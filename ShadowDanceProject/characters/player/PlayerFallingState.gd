extends PlayerState


func enter(values : Dictionary) -> void:
	player.change_to_standup_model()

func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	if player.is_on_wall() && Input.is_action_pressed("MOVE_SINK"):
		state_machine.transtion_to("PlayerSinkState", {})

	if not player.player_is_on_floor():
		player.baseVelocity.y -= player.gravity * delta
	
	if player.player_is_on_floor():
		state_machine.transtion_to("PlayerNormalState", {})

func physics_update(delta : float) -> void:
	pass


func exit() -> void:
	pass

