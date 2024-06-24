class_name StateMachine
extends Node

signal transitioned(state_name)

@export var initial_state : = NodePath()
var state : State = null

func _enter_tree() -> void:
	await owner.ready
	# The state machine assigns itself to the State objects' state_machine property.
	# state = (ionitial_state == null if initial_state else self.get_child(0))
	# state = get_node(initial_state)
	state = get_node(initial_state) if initial_state != null else self.get_child(0);
	for child in get_children():
		child.state_machine = self as StateMachine
	state.enter({})
	

func _process(delta : float) -> void:
	state.update(delta)

func _physics_process(delta : float) -> void:
	state.physics_update(delta)

func _unhandled_input(event) -> void:
	state.handle_input(event)


func transtion_to(new_state_name : String, values : Dictionary) -> void:
	if(!has_node(new_state_name)):
		push_error("State transition error. Node: " + name + " , From: " + state.name + ", To: " + new_state_name)
		return
	
	
	print(new_state_name)
	state.exit()
	var newState : State = get_node(new_state_name)
	newState.enter(values)
	state = newState
	emit_signal("transitioned", state.name)

