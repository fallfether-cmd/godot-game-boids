extends Marker3D

var sensitivity
var yaw_quat     # accumulates left/right rotation
var pitch_angle  # accumulated pitch in radians (clamped)
var player
var speed_mult

signal camera_oriented(transform_data)

func _ready() -> void:
	sensitivity = 1
	yaw_quat = Quaternion.IDENTITY
	pitch_angle = 0.0
	player = get_tree().get_root().get_node("Root/Player")
	camera_oriented.connect(player.received_camera_oriented_player)

func receive_mouse_moved_camera(mouse_velocity):
	# Accumulate yaw (horizontal) — no clamping needed
	var yaw_delta = Quaternion(Vector3.UP, -mouse_velocity.x / (500.0 * sensitivity))
	yaw_quat = (yaw_delta * yaw_quat).normalized()

	# Accumulate pitch (vertical) — clamp the TOTAL, not the delta
	pitch_angle += -mouse_velocity.y / (500.0 * sensitivity)
	pitch_angle = clamp(pitch_angle, -PI/2 + 0.05, PI/2 - 0.05)

	# Rebuild rotation from scratch each frame — no accumulation drift
	var pitch_quat = Quaternion(Vector3.RIGHT, pitch_angle)
	var final_quat = (yaw_quat * pitch_quat).normalized()

	transform.basis = Basis(final_quat).orthonormalized()

func _physics_process(_delta: float) -> void:
	#transform.origin += 1 * (transform.basis * Vector3.FORWARD)
	camera_oriented.emit(transform)
	
	transform.origin = player.transform.origin + transform.basis.z * 27
