extends Node

@export var player : PackedScene
@export var camera : PackedScene

@export var testLevelData : LevelData

var currentLoadedLevel : LevelData


# Called when the node enters the scene tree for the first time.
func _ready():
	loadLevel(testLevelData)
	EventBus.player_died.connect(player_died)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	updateUI()
	pass

func player_died(death_cause : String) -> void:
	print("player died, cause: " , death_cause)
	loadLevel(currentLoadedLevel)


func loadLevel(levelData : LevelData) -> void:
	currentLoadedLevel = levelData

	for child in $World.get_children():
		child.queue_free()
	
	for child in get_children():
		if child != $World && child != $UI:
			child.queue_free()
	


	print("Level: " , levelData.name, " has been loaded")
	var levelScene : Level = levelData.scene.instantiate()
	$World.add_child(levelScene)

	var cameraScene : Camera3D = camera.instantiate()
	add_child(cameraScene)
	
	var playerScene : Player = player.instantiate()
	playerScene.position = levelData.startPosition
	add_child(playerScene)


func updateUI() -> void:
	$UI/GameScreen/ProgressBar.min_value = 0
	$UI/GameScreen/ProgressBar.max_value = WorldGlobal.CurrentPlayer.MAXSINK_POINTS
	$UI/GameScreen/ProgressBar.value = WorldGlobal.CurrentPlayer.sinkPoints
