extends PlayerState

func enter(values : Dictionary) -> void:
	pass

func handle_input(event : InputEvent) -> void:
	pass


func update(delta : float) -> void:
	player.change_to_standup_model()


func physics_update(delta : float) -> void:
	player.CurrentSpeed = player.SPEED_NORMAL
	if not player.is_on_floor():
		state_machine.transtion_to("PlayerFallingState",  {})
		
	if Input.is_action_pressed("MOVE_SINK"):
		state_machine.transtion_to("PlayerSinkState", {})
		return
	
	# Handle jump.
	if Input.is_action_just_pressed("MOVE_JUMP") and player.is_on_floor():
		state_machine.transtion_to("PlayerJumpState", {})
	


func exit() -> void:
	pass
