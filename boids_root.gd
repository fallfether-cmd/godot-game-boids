extends Node

@export var boid_scene: PackedScene

const SUBDIVISION_COUNT = 5
const NUM_OF_BOIDS = 70

var boids = []
var boid_average_velocity
var decay_properties = {}
var player_properties = {}
var player
var subdivisions = []
var boid_linked_list

var speed_toggle = false
var billow_toggle = false

signal updated_decay_properties(data)
signal updated_player_properties(data)

# spatial partioning:
# generate an array that is 32768 in size
# use that to represent subdivisions of the area around the player, by having every 3 bits represent a subdivision of x,y,z
# get boid array index cheaply by using bitshifts, since everything is base 2
# each index of the array should either point to -1 if nothing in subdivision, or a pointer (boid id) of the HEAD of the boids in that subdivision
# have another array length(# of boids) where the idex = boid id, each boid id points to NEXT and PREV node in the double linked list
# add and remove as you would for other double linked lists
func _ready() -> void:
	randomize()
	
	decay_properties = {
		"separation_limit": Stat.new(6, 6, 1),
		"cohesion_limit": Stat.new(7, 7, 1),
		"alignment_limit": Stat.new(7, 7, 1),
		"centralization_limit": Stat.new(5, 5, 1),
		"separation_strength": Stat.new(1.8, 1.8, 1),
		"cohesion_strength": Stat.new(1.5, 1.5, 1),
		"alignment_strength": Stat.new(5, 5, 1),
		"max_vel": Stat.new(175, 175, 1),
		"max_accel": Stat.new(2, 2, 1),
	}
	
	player_properties = {
		"speed": Stat.new(0.5, 0, 1)
	}
	
	subdivisions.resize(pow(8, SUBDIVISION_COUNT))
	subdivisions.fill(-1)
	
	boid_linked_list = DoubleLinkedList.new(NUM_OF_BOIDS)
	
	
	var id = 0
	for i in range(NUM_OF_BOIDS):
		var boid = boid_scene.instantiate()
		boids.append(boid)
		updated_decay_properties.connect(boid.received_updated_decay_properties_boid)
		updated_decay_properties.emit(decay_properties)
		boid.initialize(boids, id, subdivisions, boid_linked_list) #they're all childen of this node, so it's acceptable to dump in a reference to this array... probably. it's probably cleaner to enforce unidirectional changes from here and have children signal new data but whatever
		add_child(boid)
	
	player = get_tree().get_root().get_node("Root/Player")
	updated_player_properties.connect(player.received_updated_player_properties_player)
	updated_player_properties.emit(player_properties)

func received_updated_position_boidsroot(position):
	for boid in boids:
		boid.player_pos = position

func tick_speedup():
	if speed_toggle == false:
		return Vector3.ZERO
	player_properties["speed"].value = player_properties["speed"].value + 0.04
	decay_properties["max_vel"].value = 20000
	decay_properties["max_accel"].value = 10
	decay_properties["separation_strength"].value = decay_properties["separation_strength"].value + 1
	decay_properties["separation_limit"].value = decay_properties["separation_limit"].value + 1
	
func tick_billow():
	if billow_toggle == false:
		return Vector3.ZERO
	
	player_properties["speed"].value = player_properties["speed"].value * 0.95
	decay_properties["max_vel"].value = decay_properties["max_vel"].value * 0.9
	decay_properties["max_accel"].value = decay_properties["max_vel"].value * 0.5
	decay_properties["separation_strength"].value = decay_properties["separation_strength"].value + 0.1
	decay_properties["separation_limit"].value = decay_properties["separation_limit"].value + 0.1
	decay_properties["separation_strength"].value = decay_properties["alignment_strength"].value * 0.9

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	for property in decay_properties.values():
		property.tick(delta)
	for property in player_properties.values():
		property.tick(delta)
	
	speed_toggle = false
	billow_toggle = false
	
	if Input.is_action_pressed("speed_up"):
		speed_toggle = true
	if Input.is_action_pressed("billow"):
		billow_toggle = true
	
	tick_speedup()
	tick_billow()
