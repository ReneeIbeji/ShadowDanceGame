extends PlayerState

var holdTimeLeft : float

func enter(values : Dictionary) -> void:
	player.CurrentSpeed = player.SPEED_AIR
	holdTimeLeft = player.JUMP_HOLDDOWNTIME
	player.baseVelocity.y = player.JUMP_VELOCITY

func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	pass

func physics_update(delta : float) -> void:

	if player.is_on_wall() && Input.is_action_pressed("MOVE_SINK"):
		state_machine.transtion_to("PlayerSinkState", {})

	if holdTimeLeft > 0:
		if Input.is_action_pressed("MOVE_JUMP"):
			var timeDif : float = min(delta, holdTimeLeft)
			player.baseVelocity.y += player.JUMP_VELOCITY_MAX * (timeDif  / player.JUMP_HOLDDOWNTIME)
			holdTimeLeft -= delta
		else:
			holdTimeLeft = 0  
	
	if not player.is_on_floor():
		player.baseVelocity.y -= player.gravity * delta
	
	if player.is_on_floor():
		state_machine.transtion_to("PlayerNormalState", {})



func exit() -> void:
	pass
