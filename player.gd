extends CharacterBody3D

var transform_data = Transform3D()
var boids_root
var player_properties = {}
signal updated_position(transform)

func received_camera_oriented_player(camera_transform):
	transform_data = camera_transform
	
func received_updated_player_properties_player(data):
	player_properties = data

func _ready() -> void:
	boids_root = get_tree().get_root().get_node("Root/BoidsRoot")
	updated_position.connect(boids_root.received_updated_position_boidsroot)

func _physics_process(delta: float) -> void:
	updated_position.emit(transform.origin)
	transform.origin += player_properties["speed"].value * (transform_data.basis * Vector3.FORWARD)
	move_and_slide()
