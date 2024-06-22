extends PlayerState


func enter(values : Dictionary) -> void:
	player.change_to_standup_model()

func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * delta
	
	if player.is_on_floor():
		state_machine.transtion_to("PlayerNormalState", {})

func physics_update(delta : float) -> void:
	pass


func exit() -> void:
	pass

