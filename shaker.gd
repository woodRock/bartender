extends Area2D

# --- Signals ---
signal drink_served(ingredients: Array)

# --- Nodes ---
@onready var result_sprite = $ResultSprite
@onready var liquid_bar = $Sprite2D/TextureProgressBar # Needs Fill Mode: Bottom to Top
@onready var ingredient_label = $Label

# --- State ---
var current_ingredients: Array = []

func _ready():
	# Initial UI state
	if result_sprite:
		result_sprite.visible = false
	
	if liquid_bar:
		liquid_bar.value = 0
		liquid_bar.max_value = 5 # Adjust based on your most complex recipe
	
	add_to_group("shaker")

# --- Ingredient Logic ---
func add_ingredient(ingredient_name: String):
	current_ingredients.append(ingredient_name)
	_update_label()
	_animate_liquid_fill()
	print("Added to shaker: ", ingredient_name)

func _update_label():
	if ingredient_label:
		ingredient_label.text = ", ".join(current_ingredients)

func _animate_liquid_fill():
	if not liquid_bar: return
	
	var tween = create_tween()
	# Smoothly fill the bar based on the number of items
	tween.tween_property(liquid_bar, "value", current_ingredients.size(), 0.3).set_trans(Tween.TRANS_SINE)
	
	# Color logic: Change tint based on the last ingredient added
	var last_item = current_ingredients.back().to_lower()
	if "coke" in last_item or "whiskey" in last_item:
		liquid_bar.tint_progress = Color(0.35, 0.18, 0.05) # Amber/Brown
	elif "sprite" in last_item or "vodka" in last_item:
		liquid_bar.tint_progress = Color(0.8, 0.9, 1.0, 0.7) # Clear/Light Blue
	elif "juice" in last_item:
		liquid_bar.tint_progress = Color(1.0, 0.7, 0.0) # Orange/Yellow
	else:
		liquid_bar.tint_progress = Color(1, 1, 1) # White/Default

# --- Serving Logic ---
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_ingredients.size() > 0:
			serve_drink()

func serve_drink():
	# 1. Shake Animation (Brief juice-box style jitter)
	var shake_tween = create_tween()
	shake_tween.tween_property(self, "rotation", deg_to_rad(10), 0.05)
	shake_tween.tween_property(self, "rotation", deg_to_rad(-10), 0.05)
	shake_tween.tween_property(self, "rotation", 0, 0.05)
	
	# 2. Emit signal for Main to validate
	drink_served.emit(current_ingredients)
	
	# 3. Reset the "liquid"
	var fill_tween = create_tween()
	fill_tween.tween_property(liquid_bar, "value", 0, 0.4).set_trans(Tween.TRANS_EXPO)
	
	current_ingredients.clear()
	_update_label()

# --- Visual Success Feedback ---
func show_finished_drink(tex: Texture2D):
	if tex == null or result_sprite == null: return
	
	result_sprite.texture = tex
	result_sprite.visible = true
	result_sprite.modulate.a = 0
	
	# Scaling logic to keep icons uniform
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
