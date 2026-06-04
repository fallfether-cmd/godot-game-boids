class_name DoubleLinkedList

const EMPTY = Vector2i(-2, -2)
var boids: Array[Vector2i] = []
var new_head: Vector2i
var old_head: Vector2i
var prev
var next

func _init(boids_count:int):
	boids.resize(boids_count)
	boids.fill(EMPTY)

func add(id: int, head_id:int = -1) -> void:
	if head_id == -1:
		boids[id] = Vector2i(-1, -1)
		
	assert(boids[id].x == -2, "boid must be removed before re-adding")
	
	boids[head_id].x = id
	boids[id] = Vector2i(-1, head_id)
	
func remove(id: int) -> bool:
	prev = boids[id].x
	next = boids[id].y
	if prev != -1: boids[prev].y = next
	if next != -1: boids[next].x = prev
	boids[id] = EMPTY
	return prev == -1
