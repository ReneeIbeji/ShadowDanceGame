extends PlayerState

var space_state 

var currentDirectionStart : Vector3
var currentDirection : Vector3
var currentSurfaceNormal : Vector3

var movementLog : Array[MovementPoint]

var lastPlayerPos : Vector3
var currentPlayerPos : Vector3


func enter(values : Dictionary) -> void:
	player.change_to_sink_model()
	player.CurrentSpeed = player.SPEED_SINK
	
	movementLog.clear()
	
	space_state = player.get_world_3d().direct_space_state
	
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters3D.create(player.position, player.position - player.up_direction * 2, 0b10)
	var result = space_state.intersect_ray(query)
	

	
	if result:
		currentPlayerPos = result.position
	else:
		currentPlayerPos = player.position - Vector3.UP * 1
		
		
	currentDirectionStart = currentPlayerPos
	currentDirection = player.velocity.normalized()
	currentSurfaceNormal = player.get_floor_normal()
	lastPlayerPos = player.position

func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	drawMovementPoints()
	pass


func physics_update(delta : float) -> void:
	if !player.is_on_floor():
		state_machine.transtion_to("PlayerFallingState", {})
	
	if Input.is_action_just_released("MOVE_SINK"):
		state_machine.transtion_to("PlayerNormalState", {})
	
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters3D.create(player.position, player.position - player.up_direction * 2,0b10 )
	var result = space_state.intersect_ray(query)
	if(result):
		currentPlayerPos = result.position
	else:
		currentPlayerPos = player.position - Vector3.UP * 1
	
	var loop : bool = false
	var loopStart: int = -1
	
	for i in range(movementLog.size() - 1):
		if i < 2: continue
		
		if intersect(movementLog[i].directionStart, movementLog[i+1].directionStart, currentPlayerPos, currentDirectionStart):
			print("loop! ")
			loop = true
			loopStart = i
			break
	 
	if loop:
		
		
		var newShape : ConvexPolygonShape3D = createConvexShapeFromMP(movementLog.slice(0, loopStart + 1))
		var newAreaBody : Area3D = Area3D.new()
		var newCollisionShape : CollisionShape3D = CollisionShape3D.new()
		newCollisionShape.shape = newShape
		newAreaBody.body_entered.connect(objectInLoop)
		newAreaBody.collision_mask = 0b100
		newAreaBody.add_child(newCollisionShape)
		player.get_parent().add_child(newAreaBody)
		
		
		movementLog.clear()
		
		currentDirectionStart = currentPlayerPos
		currentDirection = player.velocity.normalized() 
		

	 
	if (currentDirection != player.velocity.normalized() || currentSurfaceNormal != player.get_floor_normal()) &&  (player.velocity.normalized()     != Vector3.ZERO || movementLog.is_empty()) :
		var newPoint : MovementPoint = MovementPoint.new()
		newPoint.directionStart = currentDirectionStart
		newPoint.direction = currentDirection
		newPoint.cooldown = 1
		movementLog.push_front(newPoint)
		
		
		
		currentDirectionStart = currentPlayerPos
		currentDirection =  player.velocity.normalized()
		currentSurfaceNormal = player.get_floor_normal()
	



func exit() -> void:
	pass

func objectInLoop(body : Node3D) -> void:
	body.activate()

func createConvexShapeFromMP(points : Array[MovementPoint]) -> ConvexPolygonShape3D:
	var packedVectors : PackedVector3Array
	var average : Vector3 = Vector3.ZERO
	for point in points:
		packedVectors.append(point.directionStart)
		average += point.directionStart
	
	print(average)
	average = average / points.size()
	packedVectors.append(points[0].directionStart)
	
	for point in points:
		if point == points[0]: continue
		packedVectors.append(average)
		packedVectors.append(point.directionStart) 
	
	var result : ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	
	result.points = packedVectors
	return result

func drawMovementPoints() -> void:
	for i in range(movementLog.size() - 1):
		DebugDraw3D.draw_line(movementLog[i].directionStart, movementLog[i+1].directionStart   , Color(0,0,0),0.01)

func intersect(A,B,C,D) -> bool:
	#var da : Vector3 = B - A
	#var db : Vector3 = D - C
	#var dc : Vector3 = C - A
	#
	#if dc.dot(da.cross(db)) != 0.0:
		#return false
	#
	#var s : float = dc.cross(db).dot(da.cross(db)) / da.cross(db).length_squared()
	#
	#if s >= 0.0 and s <= 1.0:
		#var ip : Vector3 = A  + da * Vector3(s,s,s);
		#print("check")
		#if onSegment(ip, A, B)  and onSegment(ip, C, D):
			#DebugDraw3D.draw_line(ip - Vector3.UP, ip ,Color(1, 1, 0), 5)
			#return true
	#
	#return false
	
	var results : PackedVector3Array = Geometry3D.get_closest_points_between_segments(A,B,C,D)
	return roundVector(results[0]) == roundVector(results[1])

func onSegment(p : Vector3 , q : Vector3, r : Vector3) -> bool:
	return roundVector((q  - p).normalized()) == roundVector((p - r).normalized())

func roundVector(v : Vector3) -> Vector3:
	return (v * 1000).round() / 1000

class MovementPoint:
	var directionStart : Vector3
	var direction : Vector3
	var cooldown : float
	
