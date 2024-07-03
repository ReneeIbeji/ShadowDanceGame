class_name Player
extends CharacterBody3D

const MAXSTEP_HEIGHT = 0.5
const MINSTEP_HEIGHT = 0.05

const SPEED_NORMAL = 5.0
const SPEED_AIR = 4.0
const SPEED_SINK = 8
const FRIC = 1.6

const JUMP_VELOCITY = 5
const JUMP_VELOCITY_MAX = 2

const JUMP_HOLDDOWNTIME = 0.5

var moving : bool
var CurrentSpeed : float = SPEED_NORMAL

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	WorldGlobal.CurrentPlayer = self


func _physics_process(delta):
	var input_dir = Input.get_vector("MOVE_LEFT", "MOVE_RIGHT", "MOVE_FORWARD", "MOVE_BACK")
	var direction = (WorldGlobal.CurrentPlayerCamera.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * CurrentSpeed
		velocity.z = direction.z * CurrentSpeed
		$PlayerModel.look_at(global_position + velocity.normalized(), Vector3.UP)
		$PlayerModel.rotation.x = 0
	else:
		velocity.x = move_toward(velocity.x, 0, CurrentSpeed)
		velocity.z = move_toward(velocity.z, 0, CurrentSpeed)
	move_and_slide()
	#move_on_surface(velocity, delta)

func move_on_surface(movement : Vector3, delta : float) -> void:
	movement.y = 0
	var colliderRadius = 0.5
	var colliderHeight = 1
	var positionChange = movement * delta
	var space_state = get_world_3d().direct_space_state
	var forwardQuery = PhysicsRayQueryParameters3D.create(position - colliderHeight * up_direction , position + positionChange + colliderRadius * positionChange.normalized() - colliderHeight * up_direction, 0b110 )
	var result = space_state.intersect_ray(forwardQuery)
	
	if result:
		positionChange = result.position - position - colliderRadius * positionChange.normalized() + colliderHeight * up_direction
		print("hit")
		DebugDraw3D.draw_line(position - colliderHeight * up_direction, result.position,Color.RED,2)
		
		var count : int = 0
		while count < MAXSTEP_HEIGHT / MINSTEP_HEIGHT:
			var upQuery = PhysicsRayQueryParameters3D.create(result.position + Vector3.UP * MINSTEP_HEIGHT * count - Vector3.UP  * 0.1 , result.position + Vector3.UP * MINSTEP_HEIGHT * (count + 1), 0b110)
			DebugDraw3D.draw_line(result.position + Vector3.UP * MINSTEP_HEIGHT * count , result.position + Vector3.UP * MINSTEP_HEIGHT * (count + 1),Color.GREEN,2)
			space_state = get_world_3d().direct_space_state
			var newResult = space_state.intersect_ray(upQuery)
			if !newResult:
				var stepQuery = PhysicsRayQueryParameters3D.create(position  - colliderHeight * up_direction, result.position + Vector3.UP * MINSTEP_HEIGHT * count , 0b110 )
				var stepResult = space_state.intersect_ray(stepQuery)
				if !stepResult: 
					print("no hit ",count)
					positionChange = result.position + Vector3.UP * MINSTEP_HEIGHT * count - position + Vector3.UP * colliderHeight
					break
			count += 1
	
	position += positionChange


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
