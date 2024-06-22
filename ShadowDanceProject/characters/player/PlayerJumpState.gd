extends PlayerState

func enter(values : Dictionary) -> void:
	player.CurrentSpeed = player.SPEED_AIR

func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	pass
func physics_update(delta : float) -> void:
		# Handle jump
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * delta
	
	if player.is_on_floor():
		state_machine.transtion_to("PlayerNormalState", {})



func exit() -> void:
	pass
