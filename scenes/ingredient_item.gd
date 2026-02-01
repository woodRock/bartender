extends Area2D

# --- Data Link ---
@export var data: IngredientData # This is the .tres resource

# --- Audio Preloads ---
var snd_open = preload("res://assets/sounds/bottle_open.mp3")
var snd_can = preload("res://assets/sounds/can_open.mp3")
var snd_salt = preload("res://assets/sounds/salt.mp3")
var snd_sugar = preload("res://assets/sounds/sugar.mp3")
var snd_lime = preload("res://assets/sounds/lime.mp3")
var snd_coffee = preload("res://assets/sounds/coffee.mp3")
var snd_ice = preload("res://assets/sounds/ice.mp3")

# --- Nodes ---
@onready var sprite = $IngredientIcon
@onready var pour_particles = $IngredientIcon/CPUParticles2D 
@onready var sfx_one_shot = AudioStreamPlayer2D.new()
@onready var sfx_loop = AudioStreamPlayer2D.new()

# --- State ---
var dragging: bool = false
var has_opened: bool = false
var start_pos: Vector2
var active_tween: Tween
var initial_scale: Vector2
var last_mouse_pos: Vector2
var velocity: Vector2
var ingredient_name: String

func _ready():
	# 1. Initialize from Resource
	if data:
		_apply_resource_data()
	
	# 2. Setup Physics & Audio
	start_pos = global_position
	add_to_group("draggables")
	add_child(sfx_one_shot)
	add_child(sfx_loop)

func _apply_resource_data():
	ingredient_name = data.name
	initial_scale = data.initial_scale
	scale = initial_scale # Fix for tiny sprites
	
	if sprite:
		sprite.texture = data.texture
		# Recalculate offset so bottom sits on the shelf
		var tex_h = data.texture.get_height()
		sprite.offset.y = -tex_h / 2.0 if sprite.centered else -tex_h
		
		if pour_particles:
			pour_particles.color = data.color
			pour_particles.position = Vector2(0, -tex_h)
			_set_particle_amounts()

func _set_particle_amounts():
	var n = ingredient_name.to_lower()
	if "lime" in n or "mint" in n: pour_particles.amount = 5
	elif "ice" in n: pour_particles.amount = 8
	elif "salt" in n or "sugar" in n or "coffee" in n: pour_particles.amount = 40
	else: pour_particles.amount = 20

func _process(delta):
	if dragging:
		var current_mouse_pos = get_global_mouse_position()
		global_position = current_mouse_pos
		velocity = (current_mouse_pos - last_mouse_pos) / delta
		last_mouse_pos = current_mouse_pos
		
		var over_shaker = _is_over_shaker()
		var target_tilt = deg_to_rad(90.0) if over_shaker else clamp(velocity.x * -0.015, -0.6, 0.6)
		rotation = lerp_angle(rotation, target_tilt, 0.1)
		
		_handle_active_sounds()

		if active_tween == null or not active_tween.is_running():
			var stretch = clamp(velocity.length() / 3000.0, 0.0, 0.1)
			scale = scale.lerp(initial_scale * Vector2(1.0 - stretch, 1.0 + stretch), 0.2)
	else:
		last_mouse_pos = get_global_mouse_position()
		if pour_particles: pour_particles.emitting = false
		sfx_loop.stop()

func _handle_active_sounds():
	var n = ingredient_name.to_lower()
	var is_tilted = abs(rad_to_deg(rotation)) > 60.0
	
	if is_tilted:
		if pour_particles: pour_particles.emitting = true
		if "salt" in n: _play_loop(snd_salt)
		elif "sugar" in n: _play_loop(snd_sugar)
		elif "coffee" in n: _play_loop(snd_coffee)
		else: sfx_loop.stop()
	else:
		if pour_particles: pour_particles.emitting = false
		sfx_loop.stop()

func _play_loop(stream: AudioStream):
	if sfx_loop.stream != stream: sfx_loop.stream = stream
	if not sfx_loop.playing: sfx_loop.play()

func pick_up():
	if active_tween: active_tween.kill()
	if not has_opened:
		_play_open_sound()
		has_opened = true
	
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", initial_scale * Vector2(0.85, 1.2), 0.1).set_trans(Tween.TRANS_CUBIC)
	active_tween.tween_property(self, "scale", initial_scale, 0.1).set_trans(Tween.TRANS_BACK)

func _play_open_sound():
	var n = ingredient_name.to_lower()
	var silent_items = ["salt", "sugar", "coffee", "lime", "mint", "ice"]
	for item in silent_items:
		if item in n: return
		
	sfx_one_shot.stream = snd_can if data.is_can else snd_open
	sfx_one_shot.pitch_scale = randf_range(0.9, 1.1)
	sfx_one_shot.play()

func _check_drop():
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("shaker"):
			area.add_ingredient(ingredient_name)
			var n = ingredient_name.to_lower()
			if "ice" in n:
				sfx_one_shot.stream = snd_ice
				sfx_one_shot.play()
			elif "lime" in n or "mint" in n:
				sfx_one_shot.stream = snd_lime
				sfx_one_shot.play()
			break
	has_opened = false 
	_return_to_shelf()

func _return_to_shelf():
	if active_tween: active_tween.kill()
	active_tween = create_tween().set_parallel(true)
	active_tween.tween_property(self, "global_position", start_pos, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "rotation", 0.0, 0.2)
	var bounce_tween = create_tween()
	bounce_tween.tween_property(self, "scale", initial_scale * Vector2(1.15, 0.85), 0.15).set_trans(Tween.TRANS_CUBIC)
	bounce_tween.tween_property(self, "scale", initial_scale, 0.2).set_trans(Tween.TRANS_ELASTIC)

func _is_over_shaker() -> bool:
	for area in get_overlapping_areas():
		if area.is_in_group("shaker"): return true
	return false
