extends Camera3D

var followSpeed = 1
var returnSpeed = 1.5

var cameraClampMax : Vector3 = Vector3(2,3,3)
var cameraClampMin : Vector3 = Vector3(-2,-3, -0.5)


@export var targetPointScene :  PackedScene
var targetPoint : Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	WorldGlobal.CurrentPlayerCamera = self
	targetPoint = targetPointScene.instantiate()
	get_parent().add_child(targetPoint)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var currentPlayer : Player = WorldGlobal.CurrentPlayer as Player
	
	if currentPlayer:
		var distFromCamera : float = (currentPlayer.position - targetPoint.position).length()
		
		var cameraRotateInput : float = Input.get_axis("CAMERA_TURNLEFT","CAMERA_TURNRIGHT")
		
		
		
		targetPoint.rotate_y(1.5 * cameraRotateInput * delta)

		var forwardDot = -targetPoint.basis.z.dot(currentPlayer.facingDirection)

		if currentPlayer.climbing:
			var targetPosition = -targetPoint.basis.z.lerp(-currentPlayer.wall_normal, -targetPoint.basis.z.dot(-currentPlayer.wall_normal) * 3 * delta )
			targetPosition.y = 0
			targetPoint.look_at(targetPoint.position + targetPosition.reflect(-targetPoint.basis.z))
		elif is_zero_approx(cameraRotateInput)  && forwardDot > -0.8  :
			var targetPosition = -targetPoint.basis.z.lerp(currentPlayer.facingDirection,  inverse_lerp(0.8,-0.8,forwardDot) * 3 * delta )
			targetPosition.y = 0
			targetPoint.look_at(targetPoint.position + targetPosition.reflect(-targetPoint.basis.z))
		elif currentPlayer.velocity.slide(currentPlayer.up_direction).is_zero_approx() && is_zero_approx(cameraRotateInput):
			var targetPosition = -targetPoint.basis.z.lerp(currentPlayer.facingDirection,  3 * delta )
			targetPosition.y = 0
			targetPoint.look_at(targetPoint.position + targetPosition.reflect(-targetPoint.basis.z))



		targetPoint.position = currentPlayer.position + (targetPoint.position - currentPlayer.position).rotated(Vector3.UP,1.5 * cameraRotateInput * delta)
		
		var speedMulti : float = distFromCamera * 3

		targetPoint.position = targetPoint.position.move_toward(currentPlayer.position, (followSpeed if currentPlayer.velocity.length() != 0 else returnSpeed) * delta * speedMulti)
		
		var currentCMin : Vector3 = currentPlayer.position + cameraClampMin * targetPoint.basis
		var currentCMax : Vector3 = currentPlayer.position + cameraClampMax * targetPoint.basis
		#targetPoint.position = targetPoint.position.clamp(currentPlayer.position + cameraClampMin  * targetPoint.basis , currentPlayer.position + cameraClampMax * targetPoint.basis)
		
		#targetPoint.position.x = make_within_range(targetPoint.position.x, currentCMin.x, currentCMax.x)
		#targetPoint.position.y = make_within_range(targetPoint.position.y, currentCMin.y, currentCMax.y)
		#targetPoint.position.z = make_within_range(targetPoint.position.z, currentCMin.z, currentCMax.z)
		
		position = targetPoint.position + targetPoint.basis.z * 4 + Vector3.UP
		
		
		
		look_at(targetPoint.position, Vector3.UP)
	
	
	

func make_within_range(v : float, a : float, b : float):
	if a < b:
		return clamp(v, a, b)
	
	return clamp(v, b, a)

