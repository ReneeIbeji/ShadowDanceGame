class_name Interactable
extends StaticBody3D

var countdown : float = 0
var lightMaterial : StandardMaterial3D 
var darkMaterial : StandardMaterial3D

# Called when the node enters the scene tree for the first time.
func _ready():
	lightMaterial = StandardMaterial3D.new()
	lightMaterial.albedo_color = Color.WHITE
	
	darkMaterial = StandardMaterial3D.new()
	darkMaterial.albedo_color = Color.BLACK


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if countdown <= 0:
		$MeshInstance3D.material_override = lightMaterial
	else:
		countdown -= delta
	

func activate() -> void:
	$MeshInstance3D.material_override = darkMaterial
	countdown = 2.5
