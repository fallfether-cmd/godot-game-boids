extends CharacterBody3D

var acceleration
var id
var boids = []
var subdivisions
var boid_linked_list
var desired_acceleration
var player_pos = Vector3.ZERO

var decay_properties = {}

var xyz_float := PackedByteArray()
var xyz_int := PackedByteArray()
var origin := Vector3()
var bitstring : int

# let accel, cohesion, flocking, and separation all be vec3

#on init: set random vel, accel to zero, and a random orientation
#ig rotate a random amount on each of the 3 axes?
#move position to randomize a bit within each node

#per frame: 
#calc
#steer as desired_vel-current_vel
#align: calc the average position from the boid root, broadcast and pass to each boid to update
#aversion: check pos of all other boids, if within range, distace-weigh and aversion
#apply force to rotate vel vector (vel_new = vel+accel, normalized to a scalar factor)
#cohesion: local alignment, calc avg pos of neaby boids and add vector there
#after steer applied, have the vector apply to orientation
#attractor: if dist boid-origin>limit, steer towards limit based on how far away it is, increasing quadratically
func received_updated_decay_properties_boid(data):
	decay_properties = data

func initialize(boids, id, subdivisions, boid_linked_list):
	self.id = id
	self.boids = boids
	self.subdivisions = subdivisions
	self.boid_linked_list = boid_linked_list
	
	
	var max_vel = decay_properties["max_vel"].value
	
	transform.origin = Vector3(randi() % 20 - 10, randi() % 20 - 10, randi() % 20 - 10)
	velocity = Vector3(randf()*max_vel-max_vel/2, randf()*max_vel-max_vel/2, randf()*max_vel-max_vel/2)
	acceleration = Vector3(0,0,0)
	
	#get the proper subdivision
	origin = transform.origin
	xyz_float.resize(12)
	xyz_int.resize(12)
	subdivisions[get_subdivision()] = id
	#boid_linked_list.add(id)
	
	# consider negatives?
	

func get_subdivision() -> int:

	bitstring = ((int(origin.x) >> 2) & 0x1F) << 10 | ((int(origin.y) >> 2) & 0x1F) << 5 | ((int(origin.z) >> 2) & 0x1F)
	
	return bitstring
	

func get_alignment():
	var desired = Vector3(0,0,0)
	var boid_counter = 0
	var diff_pos
	var alignment_lim = decay_properties["alignment_limit"].value * decay_properties["alignment_limit"].value
	for boid in boids:
		if boid == self:
			continue
		diff_pos = boid.transform.origin - transform.origin
		if diff_pos.length_squared() < alignment_lim:
			desired += boid.velocity - velocity
			boid_counter += 1
	if boid_counter == 0:
		return Vector3.ZERO
	desired = desired/boid_counter
	return desired

func get_separation():
	var desired = Vector3(0,0,0)
	var separation_lim = decay_properties["separation_limit"].value
	for boid in boids:
		if boid == self:
			continue
		var difference = transform.origin - boid.transform.origin
		if difference.length() < separation_lim and difference.length() > 0.001:
			desired += difference*(separation_lim-difference.length())
			#desired += difference.normalized()/((CLOSENESS_LIMIT - difference.length())/CLOSENESS_LIMIT)
	return desired
	
func get_cohesion():
	var desired = Vector3(0,0,0)
	var boid_counter = 1 #counting self for +1
	var average_close_boid_position = transform.origin
	var cohesion_lim = decay_properties["cohesion_limit"].value
	for boid in boids:
		if boid == self:
			continue
		var difference = transform.origin - boid.transform.origin
		if difference.length() < cohesion_lim:
			average_close_boid_position += boid.transform.origin
			boid_counter += 1
	if boid_counter == 1:
		return Vector3.ZERO
	average_close_boid_position = average_close_boid_position/boid_counter
	desired = average_close_boid_position - transform.origin
	return desired
	
func get_inverted(length):
	var sign = sign(length)
	var centralization_lim = decay_properties["centralization_limit"].value
	var pos_diff = abs(length) - centralization_lim
	if pos_diff < 0:
		return 0
	return (-1*sign * pos_diff * pow(pos_diff, 1.3))
	
func get_centralization():
	var desired = Vector3(0,0,0)
	var relative_pos = transform.origin - player_pos
	var centralization_lim = decay_properties["centralization_limit"].value
		
	var positive_relative = abs(relative_pos)
	
	if positive_relative.x > centralization_lim:
		desired.x = get_inverted(relative_pos.x)
	if positive_relative.y > centralization_lim:
		desired.y = get_inverted(relative_pos.y)
	if positive_relative.z > centralization_lim:
		desired.z = get_inverted(relative_pos.z)
	return desired
	#return Vector3.ZERO
	
		
func _physics_process(delta: float) -> void:
	var alignment_strength = decay_properties["alignment_strength"].value
	var cohesion_strength = decay_properties["cohesion_strength"].value
	var separation_strength = decay_properties["separation_strength"].value
	var max_accel = decay_properties["max_accel"].value
	var max_vel = decay_properties["max_vel"].value
	desired_acceleration = get_alignment()*alignment_strength + get_cohesion()*cohesion_strength + get_separation()*separation_strength + get_centralization()
	acceleration = acceleration.lerp(desired_acceleration, 0.1)
	if acceleration.length() > max_accel:
		acceleration = acceleration.normalized() * max_accel
	velocity += acceleration
	if velocity.length() > max_vel:
		velocity = velocity.normalized() * max_vel
	velocity = velocity * 0.998
	
	if velocity.length() > 0.01:
		transform.basis = Basis.looking_at(velocity, Vector3.UP) * Basis(Vector3.RIGHT, PI/2)
	
	move_and_slide()
