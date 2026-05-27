extends Node3D

signal mouse_moved(velocity)
var camera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# make the cursor invisible & confine to the game window
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera = get_node("../CameraRig")
	
	mouse_moved.connect(camera.receive_mouse_moved_camera)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_moved.emit(event.screen_relative)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# set the cursor position to center of the screen?
	pass
