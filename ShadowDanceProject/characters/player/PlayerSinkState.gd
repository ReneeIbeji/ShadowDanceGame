extends PlayerState

var space_state 

var currentDirectionStart : Vector3
var currentDirection : Vector3
var currentSurfaceNormal : Vector3

var movementLog : Array[MovementPoint]

var lastPlayerPos : Vector3
var currentPlayerPos : Vector3

var loopCheckNeeded : bool
var newAreaBody : Area3D

var offFloorBuffer : float = 0.1
var offFloorCount : float


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

	offFloorCount = 0

func handle_input(event : InputEvent) -> void:
	pass

func update(delta : float) -> void:
	drawMovementPoints()
	



func physics_update(delta : float) -> void:
	if !player.player_is_on_floor() && !player.climbing:
		offFloorCount += delta
	else:
		offFloorCount = 0

	if player.climbing:
		# hook test
		var space_state := player.get_world_3d().direct_space_state
		var corner_query := PhysicsRayQueryParameters3D.create(currentPlayerPos, currentPlayerPos + -player.wall_normal * (player.collision_radius() + 0.1),0b10)

		var corner_result := space_state.intersect_ray(corner_query)

		if(!corner_result):
			for i in range(10):
				var ledge_query := PhysicsRayQueryParameters3D.create(currentPlayerPos + -player.wall_normal * (player.collision_radius() + i * 0.02), currentPlayerPos + -player.wall_normal * (player.collision_radius() + i * 0.02) - Vector3.UP * 0.1, 0b10 )
				var ledge_result := space_state.intersect_ray(ledge_query)

				if(ledge_result):
					print("hit")
					player.position = ledge_result.position + (player.collision_height() + 0.5) * player.up_direction
					DebugDraw3D.draw_line(ledge_result.position, ledge_result.position + player.collision_height() * player.up_direction, Color.BLUE, 5)
					player.velocity += Vector3.DOWN
					player.velocity -= player.wall_normal 
					break

	if player.player_is_only_on_wall():
		player.climbing = true
	elif player.player_is_on_wall():
		player.climbing = true
	else:
		player.climbing = false
	
	if loopCheckNeeded:
		for node : Interactable in newAreaBody.get_overlapping_bodies():
			node.activate.emit()
		newAreaBody.queue_free()
		newAreaBody = null
		loopCheckNeeded = false
	
	if !player.player_is_on_floor() && !(player.climbing && player.player_is_only_on_wall()) && (offFloorCount > offFloorBuffer):
		state_machine.transtion_to("PlayerFallingState", {})
	
	if Input.is_action_just_released("MOVE_SINK"):
		state_machine.transtion_to("PlayerNormalState", {})
	
	if Input.is_action_just_pressed("MOVE_JUMP"):
		player.change_to_standup_model()
		state_machine.transtion_to("PlayerJumpState", {})
	
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
		newAreaBody = Area3D.new()
		var newCollisionShape : CollisionShape3D = CollisionShape3D.new()
		newCollisionShape.shape = newShape
		newAreaBody.collision_mask = 0b100
		newAreaBody.add_child(newCollisionShape)
		player.get_parent().add_child(newAreaBody)
		print(newAreaBody.get_overlapping_areas())
		loopCheckNeeded = true

		
		
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
	player.up_direction = Vector3.UP
	player.climbing = false;


func createConvexShapeFromMP(points : Array[MovementPoint]) -> ConvexPolygonShape3D:
	var packedVectors : PackedVector3Array
	var average : Vector3 = Vector3.ZERO
	for point in points:
		packedVectors.append(point.directionStart)
		average += point.directionStart
	
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
	
