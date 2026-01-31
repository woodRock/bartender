extends Area2D

# --- Configuration ---
@export var ingredient_name: String = "Vodka"
@export var bottle_texture: Texture2D:
	set(value):
		bottle_texture = value
		_update_bottle_visuals()

# --- Nodes ---
@onready var sprite = $Sprite2D
@onready var pour_particles = $Sprite2D/CPUParticles2D 

# --- State ---
var dragging: bool = false
var start_pos: Vector2
var active_tween: Tween

# --- Physics/Movement Variables ---
var last_mouse_pos: Vector2
var velocity: Vector2

func _ready():
	start_pos = global_position
	add_to_group("draggables")
	_update_bottle_visuals()

func _update_bottle_visuals():
	# Ensure nodes exist before modifying them
	if not is_node_ready(): return
	
	if sprite and bottle_texture:
		sprite.texture = bottle_texture
		var tex_h = bottle_texture.get_height()
		
		# 1. Align pivot to the bottom center of the bottle
		if sprite.centered:
			sprite.offset.y = -tex_h / 2.0
		else:
			sprite.offset.y = -tex_h
			
		# 2. Dynamic Particle Positioning
		# Calculates the top of the bottle based on texture height
		if pour_particles:
			# We move the emitter to the very top (negative Y)
			# Subtract a few pixels (e.g., + 5) if you want it slightly inside the neck
			pour_particles.position = Vector2(0, -tex_h)
			_set_particle_color()

func _set_particle_color():
	var n = ingredient_name.to_lower()
	if "coke" in n or "whiskey" in n:
		pour_particles.color = Color(0.35, 0.18, 0.05) # Amber/Brown
	elif "juice" in n:
		pour_particles.color = Color(1.0, 0.75, 0.0) # Yellow/Orange
	elif "sprite" in n or "vodka" in n or "gin" in n:
		pour_particles.color = Color(0.85, 0.95, 1.0, 0.6) # Clear/Light Blue
	else:
		pour_particles.color = Color.WHITE

func _process(delta):
	if dragging:
		var current_mouse_pos = get_global_mouse_position()
		global_position = current_mouse_pos
		
		# 1. Physics Calculations
		velocity = (current_mouse_pos - last_mouse_pos) / delta
		last_mouse_pos = current_mouse_pos
		
		# 2. Zone Logic: Check if we are hovering over the shaker
		var is_over_shaker = false
		for area in get_overlapping_areas():
			if area.is_in_group("shaker"):
				is_over_shaker = true
				break
		
		# 3. Dynamic Rotation
		var target_tilt: float
		if is_over_shaker:
			# Tilt 90 degrees (pouring position) when over the shaker
			target_tilt = deg_to_rad(90.0) 
		else:
			# Use physics-based tilt (trailing effect) when moving
			target_tilt = clamp(velocity.x * -0.015, -0.6, 0.6) 
		
		rotation = lerp_angle(rotation, target_tilt, 0.1)
		
		# 4. Smooth Squash & Stretch
		if active_tween == null or not active_tween.is_running():
			var speed = velocity.length()
			var stretch = clamp(speed / 3000.0, 0.0, 0.1)
			scale = scale.lerp(Vector2(1.0 - stretch, 1.0 + stretch), 0.2)
			
		# 5. Emission Logic
		# Only emit if tilted significantly (over 60 degrees)
		if abs(rad_to_deg(rotation)) > 60.0:
			if not pour_particles.emitting:
				pour_particles.emitting = true
		else:
			pour_particles.emitting = false
	else:
		last_mouse_pos = get_global_mouse_position()
		if pour_particles:
			pour_particles.emitting = false

# --- Interaction Logic ---

func pick_up():
	if active_tween: active_tween.kill()
	active_tween = create_tween()
	# "Snatch" squash effect
	active_tween.tween_property(self, "scale", Vector2(0.85, 1.2), 0.1).set_trans(Tween.TRANS_CUBIC)
	active_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)

func _check_drop():
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("shaker"):
			area.add_ingredient(ingredient_name)
			break
	_return_to_shelf()

func _return_to_shelf():
	if active_tween: active_tween.kill()
	active_tween = create_tween().set_parallel(true)
	
	# Move home with a bounce
	active_tween.tween_property(self, "global_position", start_pos, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	active_tween.tween_property(self, "rotation", 0.0, 0.3)
		
	# Landing squash effect
	var bounce_tween = create_tween()
	bounce_tween.tween_property(self, "scale", Vector2(1.15, 0.85), 0.15).set_trans(Tween.TRANS_CUBIC)
	bounce_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_ELASTIC)
