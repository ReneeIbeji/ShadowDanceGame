extends PlayerState

func enter(values : Dictionary) -> void:
	pass

func handle_input(event : InputEvent) -> void:
	if event.is_action_pressed("MOVE_JUMP") && player.playerCollisionState.floor:
		state_machine.transtion_to("PlayerJumpState", {})




func update(delta : float) -> void:
	player.change_to_standup_model()
	player.CurrentSpeed = player.SPEED_NORMAL
	if not player.playerCollisionState.floor:
		state_machine.transtion_to("PlayerFallingState",  {})
		
	if Input.is_action_pressed("MOVE_SINK"):
		state_machine.transtion_to("PlayerSinkState", {})
		return
	
	


func exit() -> void:
	pass
