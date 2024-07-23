extends PlayerState

var left_ground : bool
var holdTimeLeft : float

func enter(values : Dictionary) -> void:
	left_ground = false
	player.CurrentSpeed = player.SPEED_AIR
	holdTimeLeft = player.JUMP_HOLDDOWNTIME
	player.velocity.y = player.JUMP_VELOCITY


func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	pass

func physics_update(delta : float) -> void:

	if player.is_on_wall() && Input.is_action_pressed("MOVE_SINK"):
		player.velocity.y = 0
		state_machine.transtion_to("PlayerSinkState", {})

	if holdTimeLeft > 0:
		if Input.is_action_pressed("MOVE_JUMP"):
			var timeDif : float = min(delta, holdTimeLeft)
			player.velocity.y += player.JUMP_VELOCITY_MAX * (timeDif  / player.JUMP_HOLDDOWNTIME)
			holdTimeLeft -= delta
		else:
			holdTimeLeft = 0  
	
	if !player.is_on_floor():
		player.velocity.y -= player.gravity * delta
		left_ground = true
	
	if player.is_on_floor() && left_ground:
		state_machine.transtion_to("PlayerNormalState", {})



func exit() -> void:
	pass
