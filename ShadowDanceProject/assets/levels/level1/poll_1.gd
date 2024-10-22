extends Interactable

@export var platformController : Node3D
var darkMaterial : StandardMaterial3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	activate.connect(activateAction)
	darkMaterial = StandardMaterial3D.new()
	darkMaterial.albedo_color = Color.BLACK
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func activateAction() -> void:
	$MeshInstance3D.material_override = darkMaterial
	print("activated")
	platformController.moveTowardsPosition(1)
