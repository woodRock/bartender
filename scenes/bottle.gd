extends Area2D

# --- Configuration ---
@export var ingredient_name: String = "Vodka"
@export var bottle_texture: Texture2D:
	set(value):
		bottle_texture = value
		_update_bottle_visuals()

# --- Audio Preloads ---
var snd_open = preload("res://assets/sounds/bottle_open.mp3")
var snd_can = preload("res://assets/sounds/can_open.mp3")
var snd_pour = preload("res://assets/sounds/pour.mp3")

# --- Nodes ---
@onready var sprite = $Sprite2D
@onready var pour_particles = $Sprite2D/CPUParticles2D 
@onready var sfx_open = AudioStreamPlayer2D.new()
@onready var sfx_pour = AudioStreamPlayer2D.new()

# --- State ---
var dragging: bool = false
var has_opened: bool = false
var start_pos: Vector2
var active_tween: Tween
var last_mouse_pos: Vector2
var velocity: Vector2
var initial_scale: Vector2

func _ready():
	initial_scale = scale # Captures your (4.0, 4.0) or whatever you set in editor
	start_pos = global_position
	add_to_group("draggables")
	
	add_child(sfx_open)
	add_child(sfx_pour)
	sfx_pour.stream = snd_pour
	
	_update_bottle_visuals()

func _update_bottle_visuals():
	if not is_node_ready(): return
	if sprite and bottle_texture:
		sprite.texture = bottle_texture
		var tex_h = bottle_texture.get_height()
		sprite.offset.y = -tex_h / 2.0 if sprite.centered else -tex_h
		if pour_particles:
			pour_particles.position = Vector2(0, -tex_h)
			_set_particle_color()

func _set_particle_color():
	var n = ingredient_name.to_lower()
	if "coke" in n or "whiskey" in n:
		pour_particles.color = Color(0.35, 0.18, 0.05)
	elif "juice" in n:
		pour_particles.color = Color(1.0, 0.75, 0.0)
	elif "sprite" in n or "vodka" in n or "gin" in n:
		pour_particles.color = Color(0.85, 0.95, 1.0, 0.6)
	else:
		pour_particles.color = Color.WHITE

func _process(delta):
	if dragging:
		var current_mouse_pos = get_global_mouse_position()
		global_position = current_mouse_pos
		velocity = (current_mouse_pos - last_mouse_pos) / delta
		last_mouse_pos = current_mouse_pos
		
		var is_over_shaker = false
		for area in get_overlapping_areas():
			if area.is_in_group("shaker"):
				is_over_shaker = true
				break
		
		var target_tilt = deg_to_rad(90.0) if is_over_shaker else clamp(velocity.x * -0.015, -0.6, 0.6)
		rotation = lerp_angle(rotation, target_tilt, 0.1)
		
		if abs(rad_to_deg(rotation)) > 60.0:
			pour_particles.emitting = true
			if not sfx_pour.playing:
				sfx_pour.pitch_scale = randf_range(0.95, 1.05)
				sfx_pour.play()
		else:
			pour_particles.emitting = false
			sfx_pour.stop()

		# PHYSICS SCALING FIX
		if active_tween == null or not active_tween.is_running():
			var stretch = clamp(velocity.length() / 3000.0, 0.0, 0.1)
			# Apply stretch relative to the initial_scale
			var target_scale = initial_scale * Vector2(1.0 - stretch, 1.0 + stretch)
			scale = scale.lerp(target_scale, 0.2)
	else:
		last_mouse_pos = get_global_mouse_position()
		pour_particles.emitting = false
		sfx_pour.stop()

func pick_up():
	if active_tween: active_tween.kill()
	
	if not has_opened:
		var can_types = ["coke", "sprite", "soda", "ginger ale"]
		var is_can = false
		for type in can_types:
			if type in ingredient_name.to_lower():
				is_can = true
				break
		
		sfx_open.stream = snd_can if is_can else snd_open
		sfx_open.pitch_scale = randf_range(0.9, 1.1)
		sfx_open.play()
		has_opened = true

	active_tween = create_tween()
	# Multiply pick-up "squash" by initial_scale
	var drag_scale = initial_scale * Vector2(0.85, 1.2)
	active_tween.tween_property(self, "scale", drag_scale, 0.1).set_trans(Tween.TRANS_CUBIC)
	active_tween.tween_property(self, "scale", initial_scale, 0.1).set_trans(Tween.TRANS_BACK)

func _check_drop():
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("shaker"):
			area.add_ingredient(ingredient_name)
			break
	has_opened = false 
	_return_to_shelf()

func _return_to_shelf():
	if active_tween: active_tween.kill()
	active_tween = create_tween().set_parallel(true)
	active_tween.tween_property(self, "global_position", start_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "rotation", 0.0, 0.3)
		
	var bounce_tween = create_tween()
	# FIX: Landing bounce respects original size
	bounce_tween.tween_property(self, "scale", initial_scale * Vector2(1.15, 0.85), 0.15).set_trans(Tween.TRANS_CUBIC)
	bounce_tween.tween_property(self, "scale", initial_scale, 0.2).set_trans(Tween.TRANS_ELASTIC)
