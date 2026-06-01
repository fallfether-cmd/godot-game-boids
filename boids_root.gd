extends Node

@export var boid_scene: PackedScene
var boids = []
var boid_average_velocity
var decay_properties = {}
var player_properties = {}
var player

var speed_toggle = false
var billow_toggle = false

signal updated_decay_properties(data)
signal updated_player_properties(data)

# Called when the node enters the scene tree for the first time.
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
	
	var id = 0
	for i in range(70):
		var boid = boid_scene.instantiate()
		boids.append(boid)
		updated_decay_properties.connect(boid.received_updated_decay_properties_boid)
		updated_decay_properties.emit(decay_properties)
		boid.initialize(boids, id) #they're all childen of this node, so it's acceptable to dump in a reference to this array... probably. it's probably cleaner to enforce unidirectional changes from here and have children signal new data but whatever
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
