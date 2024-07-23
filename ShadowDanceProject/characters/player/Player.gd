class_name Player
extends CharacterBody3D

const MAXSTEP_HEIGHT = 0.5
const MINSTEP_HEIGHT = 0.05

const SPEED_NORMAL = 5.0
const SPEED_AIR = 4.0
const SPEED_SINK = 8
const SPEED_CLIMB = 10
const FRIC = 1.6

const JUMP_VELOCITY = 5
const JUMP_VELOCITY_MAX = 2

const JUMP_HOLDDOWNTIME = 0.5

var moving : bool
var climbing : bool
var CurrentSpeed : float = SPEED_NORMAL
var baseVelocity : Vector3 = Vector3.ZERO

var motion_results : Array[KinematicCollision3D]
var previous_position : Vector3
var last_motion : Vector3

var playerCollsionState : CollisionState
var wall_normal : Vector3
var floor_normal : Vector3
var floor_depth : Vector3

var platform_ceiling_velocity : Vector3
var ceiling_normal : Vector3


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	WorldGlobal.CurrentPlayer = self
	playerCollsionState = CollisionState.new()


func _physics_process(delta):

	var input_dir = Input.get_vector("MOVE_LEFT", "MOVE_RIGHT", "MOVE_FORWARD", "MOVE_BACK")
	var direction = (WorldGlobal.CurrentPlayerCamera.basis * (Vector3(input_dir.x, 0, input_dir.y))).normalized()
	
	if direction:
		baseVelocity.x = direction.x * CurrentSpeed
		baseVelocity.z = direction.z * CurrentSpeed
		$PlayerModel.look_at(global_position + baseVelocity.normalized(), Vector3.UP)
		$PlayerModel.rotation.x = 0
	else:
		baseVelocity.x = move_toward(baseVelocity.x, 0, CurrentSpeed)
		baseVelocity.z = move_toward(baseVelocity.z, 0, CurrentSpeed)

	velocity = baseVelocity
	move_on_surface(velocity, delta)
	
	if position.y < -10:
		EventBus.player_died.emit("fallen")


		
	

func change_to_standup_model():
	$PlayerModel.show()
	$StandCollisionShape.disabled = false
	$SinkModel.hide()
	$SinkCollisionShape.disabled = true

func change_to_sink_model():
	$PlayerModel.hide()
	$StandCollisionShape.disabled = true
	$SinkModel.show()
	$SinkCollisionShape.disabled = false

func move_on_surface(movement : Vector3, delta : float) -> bool:
	var maxCollisons : int = 6
	
	# Skipping axis lock for movement for now

	var gt : Transform3D = get_global_transform()
	previous_position = gt.origin

	motion_results.clear()

	var was_on_floor : bool = playerCollsionState.floor
	playerCollsionState.state = 0

	last_motion = Vector3.ZERO

	# Skipping implementing moving platforms for now

	if motion_mode == MOTION_MODE_GROUNDED:
		_move_and_slide_grounded(delta, was_on_floor)
	
	# Skipping calculating real velocity

	return (motion_results.size() > 0)





func _move_and_slide_grounded(delta : float, was_on_floor : bool) -> void:
	var motion : Vector3 = velocity * delta
	var motion_slide_up : Vector3 = motion.slide(up_direction)
	var prev_floor_normal : Vector3 = floor_normal

	floor_normal = Vector3.ZERO
	wall_normal = Vector3.ZERO
	ceiling_normal = Vector3.ZERO


	# No sliding on first attempt to keep floor motion stable when possibe._add_constant_central_force
	# When stop on slope is enabled or when there is no up direction
	var sliding_enabled : bool = !floor_stop_on_slope
	# Constant speed can be applied only the first time sliding is enabled
	var can_apply_constant_speed : bool = sliding_enabled
	# If the platform's ceiing push down the body
	var apply_ceiling_velocity : bool = false
	var first_slide : bool = true
	var vel_dir_facing_up = velocity.dot(up_direction) > 0
	var total_travel : Vector3 = Vector3.ZERO

	for iteration in range (0, max_slides, 1):

		var max_collisions : int =  6
		var recovery_as_collision : bool = true

		var result : KinematicCollision3D = null
		result = move_and_collide(velocity * delta, false, 0.001, recovery_as_collision, max_collisions)

		if (result):
			last_motion = result.get_travel()
		else:
			last_motion = velocity * delta
		
		var collided : bool = (result != null)
		if(collided):
			motion_results.push_back(result)

			var previous_state : CollisionState = CollisionState.new()
			previous_state.wall = playerCollsionState.wall
			previous_state.floor = playerCollsionState.floor
			previous_state.ceiling = playerCollsionState.ceiling

			
			
			var result_state : CollisionState = CollisionState.new()
			var temp : CollisionState = CollisionState.new()
			temp.floor = true
			temp.wall = true
			temp.ceiling = true
			playerCollsionState = CollisionState.new()
			set_collision_direction(result, result_state, temp)

			if playerCollsionState.ceiling && platform_ceiling_velocity != Vector3.ZERO && platform_ceiling_velocity.dot(up_direction) < 0:
				if !slide_on_ceiling || motion.dot(up_direction) < 0 || (ceiling_normal + up_direction).length() < 0.01:
					apply_ceiling_velocity = true
					var ceiling_vertical_velocity : Vector3 = up_direction * up_direction.dot(platform_ceiling_velocity)
					var motion_vertical_velocity : Vector3 = up_direction * up_direction.dot(velocity)
					if motion_vertical_velocity.dot(up_direction) > 0 || ceiling_vertical_velocity.length_squared() > motion_vertical_velocity.length_squared():
						velocity = ceiling_vertical_velocity + velocity.slide(up_direction)

			if playerCollsionState.floor && floor_stop_on_slope && (velocity.normalized() + up_direction).length() < 0.01:
				var gt : Transform3D = get_global_transform()
				if result.get_travel().length() <= safe_margin:
					gt.origin -= result.get_travel()
				
				global_transform = gt
				velocity = Vector3.ZERO
				motion = Vector3.ZERO
				last_motion = Vector3.ZERO
				break

			if playerCollsionState.floor && motion.dot(up_direction) < 0 && first_slide:
				velocity = velocity.slide(floor_normal)			
				print(floor_normal)
				first_slide = false
				continue
				

			if result.get_remainder().is_zero_approx():
				motion = Vector3.ZERO
				break
			
			# Apply regular sliding by default
			var apply_default_sliding : bool = true

			# Wall collision checks
			if result_state && (motion_slide_up.dot(wall_normal) <= 0):
				if (floor_block_on_wall):
					# Need horizontal motion from current motion instead of motion slide up
					# to properly test the andle and avoid standing on slops
					var horizontal_motion : Vector3 = motion.slide(up_direction)
					var horizontal_normal = wall_normal.slide(up_direction).normalized()
					var motion_angle : float = abs(acos(-horizontal_normal.dot(horizontal_motion.normalized())))

					# Avoid to move forward on a wall if floor block_on_wall is true.
					# Applies only when the motion angle is under 90 degrees,
					# In order to avoid blocking lateral motion along a wall
					if (motion_angle < .5 * PI):
						apply_default_sliding = false
						if (was_on_floor && !vel_dir_facing_up):
							# Cancel the motion
							var gt : Transform3D = global_transform
							var travel_total : float = result.get_travel().length()
							if travel_total <= safe_margin:
								gt.origin -= result.get_travel()
								# TODO: Can't cancel travel, will need to fix soon
							elif travel_total < max(0.01, safe_margin * 20):
								gt.origin -= result.get_travel().slide(up_direction)
								# Keep remaing motion in sync with amount cancled.
								motion = motion.slide(up_direction)
								# Still can't cancel motion
							else:
								# result.travel = result.travel.slide(up_direction);
								
								motion = (result.get_remainder() + result.get_travel()).slide(up_direction)
							
							global_transform = gt
							_snap_on_floor(true, false)
						else:
							# If the movement is not cancelled we only keep the remaing
							motion = result.get_remainder()
						
						# Apply slide on forward in order to allow only lateral motion on next step
						var forward : Vector3 = wall_normal.slide(up_direction).normalized()
						motion = motion.slide(forward)

						# Scales the horiontal velocity acording to the wall slope
						if(vel_dir_facing_up):
							var slide_motion : Vector3 = velocity.slide(result.get_normal(0))
							# Keeps the vertical motion from velocity and add the horizontal motion of the projection.
							velocity = up_direction * up_direction.dot(velocity) + slide_motion.slide(up_direction)
						else:
							velocity = velocity.slide(forward)

						# Allow only lateral motion along previous floor when already on floor
						# Fixes slowing down when moving in diagonal against an inclined wal 
						if(was_on_floor &&  !vel_dir_facing_up && (motion.dot(up_direction) > 0.0)):
							var floor_side : Vector3 = prev_floor_normal.cross(wall_normal)
							if (floor_side != Vector3.ZERO):
								motion = floor_side * motion.dot(floor_side)

						# Stop all motion when a second wall is hit (unless sliding down or jumping),
						# in order to avoid jittering in corner cases
						var stop_all_motion = previous_state.wall && !vel_dir_facing_up

						# Allow sliding when the body falls
						if !playerCollsionState.floor && motion.dot(up_direction) < 0:
							var slide_motion : Vector3 = motion.slide(wall_normal)

							# Test again to allow sliding only if the result goes dowards.
							# Fixes jittering issues at the bottom of inclined walls.
							if slide_motion.dot(up_direction) < 0:
								stop_all_motion  = false
								motion = slide_motion
					
						if stop_all_motion:
							motion = Vector3.ZERO
							velocity = Vector3.ZERO
				# top horizontal motion when under wall slide threshold
				if was_on_floor && (wall_min_slide_angle > 0.0) && result_state.wall:
					var horizontal_normal : Vector3 = wall_normal.slide(up_direction).normalized()
					var motion_angle : float = abs(acos(-horizontal_normal.dot(motion_slide_up.normalized())))
					if(motion_angle < wall_min_slide_angle):
						motion = up_direction * motion.dot(up_direction)
						velocity = up_direction * velocity.dot(up_direction)

						apply_default_sliding = false

			if apply_default_sliding:
				# Regular sliding, the last part of the test handle the case when you don't want to slide on the ceiling
				if (sliding_enabled ||  !playerCollsionState.floor) && (!playerCollsionState.ceiling || slide_on_ceiling || !vel_dir_facing_up) && !apply_ceiling_velocity:
					var slide_motion : Vector3 = result.get_remainder().slide(result.get_normal(0))
					if (playerCollsionState.floor && !playerCollsionState.wall && !motion_slide_up.is_zero_approx()):
						# Slide using the intersection between the motion plane and the floor plane._add_constant_central_force
						# in order to keep the direct intact.
						var motion_length : float = slide_motion.length()
						slide_motion = up_direction.cross(result.get_remainder()).cross(floor_normal)

						# keep the length from default slide to change speed in slopes by default
						# when constant speed is not enabled. 
						slide_motion = slide_motion.normalized()
						slide_motion *= motion_length
					
					if slide_motion.dot(velocity) > 0.0:
						motion = slide_motion 
					else:
						motion = Vector3.ZERO
					
					if slide_on_ceiling && result_state.ceiling:
						# Apply slide only in the direction of the input motion, otherwise just stop to avoid jittering when moving against a wall.
						if vel_dir_facing_up:
							velocity = velocity.slide(result.get_normal(0))
						else:
						# Avoid acceleration in a slope when falling.
							velocity = up_direction * up_direction.dot(velocity)
		
				# No sliding on first attempt to keep floor motion stable when possible. 
				else:
					motion = result.get_remainder()
					if(result_state.ceiling && !slide_on_ceiling && vel_dir_facing_up):
						velocity = velocity.slide(up_direction)
						motion = motion.slide(up_direction)

			total_travel += result.get_travel()
			
			# Apply Constant Speed
			if (was_on_floor && floor_constant_speed && can_apply_constant_speed && playerCollsionState.floor && !motion.is_zero_approx()):
				var travel_slide_up : Vector3 = total_travel.slide(up_direction)
				motion = motion.normalized() * max(0,(motion_slide_up.length() - travel_slide_up.length()))

		# When you move forward in a downward slope you don't collide because you will be in the air.
		# This test ensures that constant speed is applied, only if the player is still on the ground after the snap is applied.
		elif floor_constant_speed && first_slide && _on_floor_if_snapped(was_on_floor, vel_dir_facing_up):
			can_apply_constant_speed = false
			sliding_enabled = true
			var gt : Transform3D = get_global_transform()
			gt.origin = gt.origin - result.get_travel()
			global_transform = gt

			# Slide using the intersection between the motion plane and the floor plane,
			#  In order to keep the direction intact.
			var motion_slide_norm = up_direction.cross(motion).cross(prev_floor_normal)
			motion_slide_norm = motion_slide_norm.normalized()

			motion = motion_slide_norm * (motion_slide_up.length())
			collided = true
		
		else:
			playerCollsionState  = CollisionState.new()
		


		if !collided || motion.is_zero_approx():
			break
		
		can_apply_constant_speed = !can_apply_constant_speed && !sliding_enabled
		sliding_enabled = true
		first_slide =false
		
		# Reset tne gravity accumulation when touching the ground.
		if playerCollsionState.floor && !vel_dir_facing_up:
			velocity = velocity.slide(up_direction)


	_snap_on_floor(was_on_floor, vel_dir_facing_up)

	

func set_collision_direction(result : KinematicCollision3D, r_state : CollisionState, apply_state : CollisionState ) -> void:
	r_state.state = 0

	var wall_depth : float = -1.0
	var floor_depth : float = -1.0
	var wasOnWall : bool = playerCollsionState.wall
	var prev_wall_normal : Vector3 = wall_normal
	var wall_collision_count : int = 0;
	var combined_wall_normal : Vector3;
	var tmp_wall_col : Vector3;

	for i in range(result.get_collision_count() -1 , -1, -1):
		if (motion_mode == MOTION_MODE_GROUNDED):
			var floor_angle = result.get_angle(i,up_direction)
			if(floor_angle <= floor_max_angle + 0.01):
				r_state.floor = true;
				if (apply_state.floor && result.get_depth() > floor_depth):
					playerCollsionState.floor = true;
					floor_normal =  result.get_normal(i)
					floor_depth = result.get_depth()
				continue

		# Check if any collision is ceiling.
		var ceiling_angle := result.get_angle(i, -up_direction)
		if ceiling_angle <= floor_max_angle + 0.01 :
			r_state.ceiling = true;
			if (apply_state.ceiling):
				# platform_ceiling_velocity = result.get_collider(i).collider_velocity
				ceiling_normal = result.get_normal(i);
				playerCollsionState.ceiling = true;
			
			continue
		
		# Collision is wall by default
		r_state.wall = true

		if apply_state.wall && result.get_depth() > wall_depth:
			playerCollsionState.wall = true
			wall_depth = result.get_depth()
			wall_normal = result.get_normal(i)

			# Don't apply wall velocity when the collider is a CharacterBody3D.
			# Not bothering with moving platforms for now

			# Collect normal for calculating average.
		if (!result.get_normal(i).is_equal_approx(tmp_wall_col)):
			tmp_wall_col = result.get_normal(i)
			combined_wall_normal += combined_wall_normal.normalized();
			wall_collision_count += 1

	if r_state.wall:
		if wall_collision_count > 1 && motion_mode == MOTION_MODE_GROUNDED:
			combined_wall_normal =combined_wall_normal.normalized();
			var floor_angle : float = acos(combined_wall_normal.dot(up_direction))
			if (floor_angle <= floor_max_angle + 0.01):
				r_state.floor = true;
				r_state.wall = false;
				if apply_state.floor:
					playerCollsionState.floor = true 
					floor_normal = combined_wall_normal
				if (apply_state.wall):
					playerCollsionState.wall = wasOnWall
					wall_normal = prev_wall_normal
				return
	
func _on_floor_if_snapped(was_on_floor : bool , vel_dir_facing_up : bool) -> bool:
	if up_direction == Vector3.ZERO || playerCollsionState.floor || !was_on_floor || vel_dir_facing_up:
		return false
	
	var length : float = max(floor_snap_length, safe_margin)

	const max_collisons : int = 4
	const recovery_as_collision = true
	const collide_separation_ray = true
	

	var result : KinematicCollision3D
	result = move_and_collide(-up_direction * length , true, safe_margin,  true, max_collisons)
	if result != null:
		var result_state : CollisionState = CollisionState.new()
		set_collision_direction(result,result_state,CollisionState.new())

		return result_state.floor
	
	return false

func _snap_on_floor(was_on_floor : bool, vel_dir_facing_up : bool) -> void:
	if playerCollsionState.floor || !was_on_floor || vel_dir_facing_up:
		return
	
	player_apply_floor_snap()

func player_apply_floor_snap() -> void :
	if playerCollsionState.floor:
		return
	
	var length  : float = max(floor_snap_length,safe_margin)

	const max_collisons : int = 4
	const recovery_as_collision = true
	const collide_separation_ray = true

	var result : KinematicCollision3D = move_and_collide(-up_direction * length, true, 0.001,recovery_as_collision, max_collisons )

	if  result:
		var result_state : CollisionState = CollisionState.new()
		var floor_state : CollisionState = CollisionState.new()
		floor_state.floor = true
		set_collision_direction(result, result_state, floor_state)
		
		if result_state.floor:
			if floor_stop_on_slope:
				if result.get_travel().length() > safe_margin:
					position += up_direction * up_direction.dot(result.get_travel())


	





func player_is_on_floor() -> bool:
	return playerCollsionState.floor
		


class CollisionState:
	var state : int = 0 
	var floor : bool
	var wall : bool
	var ceiling : bool

