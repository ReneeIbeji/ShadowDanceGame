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

var currentCameraBasis : Basis
var currentInputDir : Vector2


var moving : bool
var swimming : bool 
var climbing : bool
var CurrentSpeed : float = SPEED_NORMAL
var baseVelocity : Vector3 = Vector3.ZERO
var facingDirection : Vector3

var playerCollisionState : CollisionState

var floor_normal : Vector3
var wall_normal : Vector3
var ceiling_normal : Vector3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	WorldGlobal.CurrentPlayer = self
	playerCollisionState = CollisionState.new(false, false, false)
	facingDirection = -basis.z
	currentCameraBasis = WorldGlobal.CurrentPlayerCamera.basis
	currentInputDir = Vector2.ZERO


func _physics_process(delta):
	var input_dir = Input.get_vector("MOVE_LEFT", "MOVE_RIGHT", "MOVE_FORWARD", "MOVE_BACK")
	currentCameraBasis = WorldGlobal.CurrentPlayerCamera.basis


	var direction = (currentCameraBasis * (Vector3(input_dir.x, 0, input_dir.y))).normalized()
	
	if direction:
		velocity.x = direction.x * CurrentSpeed
		velocity.z = direction.z * CurrentSpeed
		$PlayerModel.look_at(global_position + velocity.normalized(), Vector3.UP)
		$PlayerModel.rotation.x = 0
	else:
		velocity.x = move_toward(velocity.x, 0, CurrentSpeed)
		velocity.z = move_toward(velocity.z, 0, CurrentSpeed)
	
	# move_and_slide()
	player_move(velocity, delta)

	if !velocity.slide(up_direction).is_zero_approx():
		facingDirection = velocity.slide(up_direction).normalized() * global_basis
	
	if position.y < -10:
		EventBus.player_died.emit("fallen")


func player_move(var_velocity : Vector3, var_delta : float) -> void:
	var first_slide : bool = true

	var remaining_motion : Vector3 = var_velocity * var_delta

	var previousCollisionState : CollisionState = CollisionState.new(false, false, false)
	


	previousCollisionState = CollisionState.new(playerCollisionState.floor, playerCollisionState.wall ,playerCollisionState.ceiling)
	playerCollisionState = CollisionState.new(false,false,false)

	for i in range(1000):
		var collision_result : KinematicCollision3D = move_and_collide(remaining_motion, false, 0.001, false, 6)
		var collision : bool = (collision_result != null)

		if collision:
			playerCollisionState = CollisionState.new(false,false,false)
			remaining_motion -= collision_result.get_travel()
			var result_state : CollisionState = CollisionState.new(false, false, false)
			
			set_collision_direction(collision_result, result_state, CollisionState.new(true, true, true))

			

			if playerCollisionState.floor:
				if remaining_motion.dot(-up_direction) > 0 && floor_normal.is_equal_approx(up_direction):
					remaining_motion -= remaining_motion.dot(-up_direction) * -up_direction
				if remaining_motion.dot(-floor_normal) > 0: 
					remaining_motion -= remaining_motion.dot(-floor_normal) * -floor_normal

			if playerCollisionState.wall && remaining_motion.dot(-wall_normal) > 0:
				if climbing && first_slide:
					remaining_motion.y = remaining_motion.dot(-wall_normal)
					velocity = velocity.slide(up_direction)
					first_slide = false
					continue
				else:
					remaining_motion -= remaining_motion.dot(-wall_normal) * -wall_normal
				
			
			if playerCollisionState.ceiling:
				remaining_motion -= remaining_motion.dot(-ceiling_normal) * -ceiling_normal

			_snap_on_floor(previousCollisionState.floor, velocity.dot(up_direction) > 0)

		else:
			remaining_motion = Vector3.ZERO
		
		if(remaining_motion.is_zero_approx()):
			break
		


	_snap_on_floor(previousCollisionState.floor, velocity.dot(up_direction) > 0)


		


	

func change_to_standup_model() -> void:
	$PlayerModel.show()
	$StandCollisionShape.disabled = false
	$SinkModel.hide()
	$SinkCollisionShape.disabled = true

func change_to_sink_model() -> void:
	$PlayerModel.hide()
	$StandCollisionShape.disabled = true
	$SinkModel.show()
	$SinkCollisionShape.disabled = false


func _snap_on_floor(was_on_floor : bool, vel_dir_facing_up : bool) -> void:
	if playerCollisionState.floor || !was_on_floor || vel_dir_facing_up:
		return

	player_apply_floor_snap()

func player_apply_floor_snap() -> void:
	if playerCollisionState.floor:
		return

	var length  : float = max(floor_snap_length,safe_margin)

	const max_collisons : int = 4
	const recovery_as_collision = true

	var result : KinematicCollision3D = move_and_collide(-up_direction * length, true, 0.001,recovery_as_collision, max_collisons )

	if  result:
		var result_state : CollisionState = CollisionState.new(false,false,false)
		var floor_state : CollisionState = CollisionState.new(false,false,true)
		set_collision_direction(result, result_state, floor_state)

		if result_state.floor:
			if floor_stop_on_slope:
				if result.get_travel().length() > safe_margin:
					position += up_direction * up_direction.dot(result.get_travel())




func set_collision_direction(result : KinematicCollision3D, r_state : CollisionState, apply_state : CollisionState ) -> void:
	var wall_depth : float = -1.0
	var floor_depth : float = -1.0
	var wasOnWall : bool = playerCollisionState.wall
	var prev_wall_normal : Vector3 = wall_normal
	var wall_collision_count : int = 0;
	var combined_wall_normal : Vector3;
	var tmp_wall_col : Vector3;

	for i in range(result.get_collision_count() -1 , -1, -1):
		var floor_angle = result.get_angle(i,up_direction)
		if(floor_angle <= floor_max_angle + 0.01):
			r_state.floor = true;
			if (apply_state.floor && result.get_depth() > floor_depth):
				playerCollisionState.floor = true;
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
				playerCollisionState.ceiling = true;

			continue

		# Collision is wall by default
		r_state.wall = true

		if apply_state.wall && result.get_depth() > wall_depth:
			playerCollisionState.wall = true
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
					playerCollisionState.floor = true 
					floor_normal = combined_wall_normal
				if (apply_state.wall):
					playerCollisionState.wall = wasOnWall
					wall_normal = prev_wall_normal
				return


class CollisionState:
	var floor : bool
	var wall : bool
	var ceiling : bool
	
	func _init(_floor : bool, _wall : bool, _ceiling : bool):
		floor = _floor
		wall = _wall
		ceiling = _ceiling


func player_is_on_floor() -> bool:
	return playerCollisionState.floor

func player_is_only_on_floor() -> bool:
	return (playerCollisionState.floor && !(playerCollisionState.wall || playerCollisionState.ceiling))

func player_is_on_wall() -> bool:
	return playerCollisionState.wall

func player_is_only_on_wall() -> bool:
	return (playerCollisionState.wall && !(playerCollisionState.floor || playerCollisionState.ceiling))


func player_is_on_ceiling() -> bool:
	return playerCollisionState.ceiling

func player_is_only_on_ceiling() -> bool:
	return (playerCollisionState.ceiling && !(playerCollisionState.floor || playerCollisionState.wall))

func collision_radius() -> float:
	return 0.5 

func collision_height() -> float:
	if swimming:
		return 0.354
	
	return 2