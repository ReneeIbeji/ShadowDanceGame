class_name LevelData	
extends Resource

@export var name : String
@export var scene : PackedScene	
@export var startPosition : Vector3

func _init( LevelName : String = "", LevelScene : PackedScene = null, LevelplayerStartPosition : Vector3 = Vector3.ZERO ):
	name = LevelName
	scene = LevelScene
	startPosition = LevelplayerStartPosition