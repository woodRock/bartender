extends Area2D

signal drink_served(ingredients: Array)

# --- Audio Preloads ---
var snd_ice = preload("res://assets/sounds/ice.mp3")
var snd_serve = preload("res://assets/sounds/shake_and_pour.mp3")

# --- Nodes ---
@onready var result_sprite = $ResultSprite
@onready var liquid_bar = $Sprite2D/TextureProgressBar 
@onready var sfx_shaker = AudioStreamPlayer2D.new()

# --- Ingredient Color Mapping ---
# Note: Use values between 0.0 and 1.0 for Color()
var color_map = {
	"tequila": Color(1.0, 0.85, 0.4),    # Gold
	"kahlua": Color(0.3, 0.15, 0.05),    # Dark Brown
	"coffee": Color(0.2, 0.1, 0.0),      # Black Coffee Brown
	"lime": Color(0.6, 1.0, 0.2),        # Bright Green
	"mint": Color(0.1, 0.8, 0.2),        # Leaf Green
	"coke": Color(0.25, 0.1, 0.05),      # Soda Brown
	"whiskey": Color(0.8, 0.4, 0.1),     # Amber
	"juice": Color(1.0, 0.7, 0.0),       # Orange/Yellow
	"vodka": Color(0.9, 0.95, 1.0, 0.6), # Clear/Pale Blue
	"gin": Color(0.9, 0.95, 1.0, 0.6),   # Clear
	"sugar": Color(1.0, 1.0, 1.0, 0.9),  # White
	"salt": Color(1.0, 1.0, 1.0, 0.9)    # White
}

var current_ingredients: Array = []

func _ready():
	add_child(sfx_shaker)
	if result_sprite: result_sprite.visible = false
	if liquid_bar: 
		liquid_bar.value = 0
		liquid_bar.show()
	add_to_group("shaker")

func add_ingredient(ingredient_name: String):
	current_ingredients.append(ingredient_name)
	
	# Play Ice SFX
	sfx_shaker.stream = snd_ice
	sfx_shaker.pitch_scale = randf_range(0.85, 1.15)
	sfx_shaker.play()
	
	_animate_liquid_fill(ingredient_name)
	
	# Squash Impact
	var original_scale = scale
	var splash_tween = create_tween()
	splash_tween.tween_property(self, "scale", original_scale * Vector2(1.1, 0.9), 0.05)
	splash_tween.tween_property(self, "scale", original_scale, 0.15).set_trans(Tween.TRANS_ELASTIC)

func _animate_liquid_fill(last_added: String):
	if not liquid_bar: return
	
	var n = last_added.to_lower()
	var tween = create_tween()
	
	# 1. Update Fill Level
	tween.tween_property(liquid_bar, "value", current_ingredients.size(), 0.3).set_trans(Tween.TRANS_SINE)
	
	# 2. Update Color Logic
	# If the ingredient is in our map, change the liquid color.
	# If it's NOT (like Ice), we do nothing, keeping the previous color.
	for key in color_map.keys():
		if key in n:
			tween.parallel().tween_property(liquid_bar, "tint_progress", color_map[key], 0.3)
			break

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_ingredients.size() > 0:
			serve_drink()

func serve_drink():
	sfx_shaker.stream = snd_serve
	sfx_shaker.play()
	
	var shake_tween = create_tween()
	shake_tween.tween_property(self, "position:x", position.x + 5, 0.05)
	shake_tween.tween_property(self, "position:x", position.x - 5, 0.05)
	shake_tween.tween_property(self, "position:x", position.x, 0.05)
	
	drink_served.emit(current_ingredients)
	
	var fill_tween = create_tween()
	fill_tween.tween_property(liquid_bar, "value", 0, 0.4).set_trans(Tween.TRANS_EXPO)
	current_ingredients.clear()

func show_finished_drink(tex: Texture2D):
	if tex == null: return
	result_sprite.texture = tex
	result_sprite.visible = true
	result_sprite.modulate.a = 0
	
	var target_size = 180.0 
	var tex_size = tex.get_size()
	var scale_factor = target_size / max(tex_size.x, tex_size.y)
	var final_scale = Vector2(scale_factor, scale_factor)
	
	result_sprite.scale = final_scale * 0.4
	var tween = create_tween().set_parallel(true)
	tween.tween_property(result_sprite, "modulate:a", 1.0, 0.3)
	tween.tween_property(result_sprite, "scale", final_scale, 0.5).set_trans(Tween.TRANS_ELASTIC)
	
	await get_tree().create_timer(1.8).timeout
	var fade_out = create_tween()
	fade_out.tween_property(result_sprite, "modulate:a", 0.0, 0.4)
	fade_out.finished.connect(func(): result_sprite.visible = false)
