extends Area2D

# --- Signals ---
signal drink_served(ingredients: Array)

# --- Nodes ---
@onready var result_sprite = $ResultSprite
@onready var liquid_bar = $Sprite2D/TextureProgressBar # Masked by parent sprite
@onready var ingredient_label = $Label

# --- State ---
var current_ingredients: Array = []

func _ready():
	if result_sprite:
		result_sprite.visible = false
	
	if liquid_bar:
		liquid_bar.value = 0
		liquid_bar.max_value = 5
	
	add_to_group("shaker")

# --- Ingredient Logic ---
func add_ingredient(ingredient_name: String):
	current_ingredients.append(ingredient_name)
	_update_label()
	_animate_liquid_fill(ingredient_name)
	
	# THE FIX: Store the original scale first
	var original_scale = scale
	var splash_tween = create_tween()
	# Multiply the current scale so it "jitters" relative to its actual size
	splash_tween.tween_property(self, "scale", original_scale * Vector2(1.1, 0.9), 0.05)
	splash_tween.tween_property(self, "scale", original_scale, 0.15).set_trans(Tween.TRANS_ELASTIC)
	
func _update_label():
	if ingredient_label:
		ingredient_label.text = ", ".join(current_ingredients)

func _animate_liquid_fill(last_added: String):
	if not liquid_bar: return
	
	var tween = create_tween()
	tween.tween_property(liquid_bar, "value", current_ingredients.size(), 0.3).set_trans(Tween.TRANS_SINE)
	
	# Tint based on ingredient type
	var n = last_added.to_lower()
	if "coke" in n or "whiskey" in n:
		liquid_bar.tint_progress = Color(0.35, 0.18, 0.05)
	elif "sprite" in n or "vodka" in n:
		liquid_bar.tint_progress = Color(0.8, 0.9, 1.0, 0.7)
	elif "juice" in n:
		liquid_bar.tint_progress = Color(1.0, 0.7, 0.0)
	else:
		liquid_bar.tint_progress = Color(1, 1, 1)

# --- Serving Logic ---
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_ingredients.size() > 0:
			serve_drink()

func serve_drink():
	# Jitter animation
	var shake_tween = create_tween()
	shake_tween.tween_property(self, "position:x", position.x + 5, 0.05)
	shake_tween.tween_property(self, "position:x", position.x - 5, 0.05)
	shake_tween.tween_property(self, "position:x", position.x, 0.05)
	
	drink_served.emit(current_ingredients)
	
	# Empty the liquid
	var fill_tween = create_tween()
	fill_tween.tween_property(liquid_bar, "value", 0, 0.4).set_trans(Tween.TRANS_EXPO)
	
	current_ingredients.clear()
	_update_label()

# --- Feedback Logic ---
func show_finished_drink(tex: Texture2D):
	if tex == null or result_sprite == null: return
	
	result_sprite.texture = tex
	result_sprite.visible = true
	result_sprite.modulate.a = 0
	
	# Normalize Icon Scale
	var target_display_size = 180.0 
	var tex_size = tex.get_size()
	var scale_factor = target_display_size / max(tex_size.x, tex_size.y)
	var final_scale = Vector2(scale_factor, scale_factor)
	
	result_sprite.scale = final_scale * 0.4
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(result_sprite, "modulate:a", 1.0, 0.3)
	tween.tween_property(result_sprite, "scale", final_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.8).timeout
	
	var fade_out = create_tween()
	fade_out.tween_property(result_sprite, "modulate:a", 0.0, 0.4)
	fade_out.finished.connect(func(): result_sprite.visible = false)
