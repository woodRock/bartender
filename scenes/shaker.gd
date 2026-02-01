extends Area2D

signal drink_served(poured_ingredients: Array)

@onready var progress_bar = $Sprite2D/TextureProgressBar

const BASE_SCALE = Vector2(2.0, 2.0)
# This defines exactly how many ingredients fill the bar (1/8 = 12.5 per item)
const FILL_PER_INGREDIENT: float = 12.5 

var ingredients_in_shaker: Array = []
var ingredient_densities: Array = []

func _ready():
	if progress_bar:
		progress_bar.max_value = 100
		progress_bar.value = 0
	
	scale = BASE_SCALE
	add_to_group("shaker")

func add_ingredient(ing_name: String, color: Color, is_solid: bool = false, density: int = 0):
	# 1. THE GATEKEEPER: Only proceed if this is a NEW ingredient being added
	# This prevents the bar from filling 60 times a second while pouring.
	if ingredients_in_shaker.is_empty() or ingredients_in_shaker.back() != ing_name:
		
		# Record the ingredient
		ingredients_in_shaker.append(ing_name)
		ingredient_densities.append(density)
		
		# 2. Increment the progress bar exactly 1/8th of the way
		if progress_bar:
			progress_bar.value += FILL_PER_INGREDIENT
			progress_bar.tint_progress = color
		
		# 3. Visual Feedback (Thump)
		_play_splash_tween()
		
		# 4. Density Check (Muddy Mix)
		if ingredient_densities.size() > 1:
			if density > ingredient_densities[-2]:
				_trigger_mix_visual()

# --- Visual Effects ---

func _play_splash_tween():
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(BASE_SCALE.x * 1.05, BASE_SCALE.y * 0.95), 0.05)
	t.tween_property(self, "scale", BASE_SCALE, 0.1).set_trans(Tween.TRANS_ELASTIC)

func _trigger_mix_visual():
	if progress_bar:
		var t = create_tween()
		t.tween_property(progress_bar, "modulate", Color.BROWN, 0.2)
		t.tween_property(progress_bar, "modulate", Color.WHITE, 0.5)

# --- Gameplay Actions ---

func serve_drink():
	if ingredients_in_shaker.is_empty(): return
	drink_served.emit(ingredients_in_shaker)
	
	# Reset
	ingredients_in_shaker.clear()
	ingredient_densities.clear()
	if progress_bar:
		progress_bar.value = 0

func show_finished_drink(icon_tex: Texture2D):
	var icon = Sprite2D.new()
	icon.texture = icon_tex
	var target_pixel_size: float = 256
	var tex_size = icon_tex.get_size()
	var normalized_scale = (target_pixel_size / tex_size.x) / BASE_SCALE.x
	icon.scale = Vector2(normalized_scale, normalized_scale)
	var final_scale = icon.scale
	icon.scale = final_scale * 0.1
	add_child(icon)
	icon.position = Vector2(0, -60) 
	var t = create_tween()
	t.tween_property(icon, "scale", final_scale, 0.4).set_trans(Tween.TRANS_BACK)
	t.tween_property(icon, "modulate:a", 0, 0.5).set_delay(1.5)
	t.tween_callback(icon.queue_free)
