extends PlayerState

var holdTimeLeft : float

func enter(values : Dictionary) -> void:
	player.CurrentSpeed = player.SPEED_AIR
	holdTimeLeft = player.JUMP_HOLDDOWNTIME

func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	pass
func physics_update(delta : float) -> void:
	if holdTimeLeft > 0:
		if Input.is_action_pressed("MOVE_JUMP"):
			var timeDif : float = min(delta, holdTimeLeft)
			player.velocity.y += player.JUMP_VELOCITY_MAX * (timeDif  / player.JUMP_HOLDDOWNTIME)
			print("Hello")
			holdTimeLeft -= delta
		else:
			holdTimeLeft = 0  
	
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * delta
	
	if player.is_on_floor():
		state_machine.transtion_to("PlayerNormalState", {})



func exit() -> void:
	pass
