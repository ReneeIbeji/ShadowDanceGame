class_name Player
extends CharacterBody3D


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
