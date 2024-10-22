extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	moveToPosition(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func moveTowardsPosition(num : int):
	for child in get_children():
		if child is SetPoints:
			child.move_towards_point(num)

func moveToPosition(num : int):
	for child in get_children():
		if child is SetPoints:
			child.set_point(num)
