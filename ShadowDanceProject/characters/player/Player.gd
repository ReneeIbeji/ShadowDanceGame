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
var baseVelocity : Vector3 = Vector3.ZERO;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	WorldGlobal.CurrentPlayer = self


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
	
	if(is_on_wall() && climbing):
		move_and_collide(Vector3(0,baseVelocity.dot(get_wall_normal()) * -1,0) * delta)
		baseVelocity=Vector3.ZERO

	velocity = baseVelocity * transform.basis
	#move_on_surface(velocity, delta)

	move_and_slide()

	if climbing && !is_on_wall() && !is_on_floor():
		velocity = baseVelocity * transform.basis
		move_and_slide()
	
	# death check
	if position.y < -10:
		EventBus.player_died.emit("fallen")

func move_on_surface(movement : Vector3, delta : float) -> void:
	move_and_collide(movement * delta)

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
