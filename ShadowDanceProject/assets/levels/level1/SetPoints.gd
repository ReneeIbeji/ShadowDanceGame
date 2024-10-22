class_name SetPoints
extends Node3D

@export var points : Array[Vector3]
var targetPoint : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !targetPoint.is_equal_approx(position):
		position = position.move_toward(targetPoint, delta * 5)

func move_towards_point( num : int):
	targetPoint = points[num]

func set_point(num : int):
	position = points[num]
	targetPoint = position
