extends Area2D

@export var ingredient_name: String = "Ice"
@export var item_texture: Texture2D:
	set(value):
		item_texture = value
		if is_node_ready():
			$IngredientIcon.texture = value

var dragging = false
var start_pos: Vector2
var active_tween: Tween
var initial_scale: Vector2

func _ready():
	initial_scale = scale 
	start_pos = global_position
	# Add to group via code to be safe
	add_to_group("draggables") 
	if item_texture:
		$IngredientIcon.texture = item_texture

func _process(_delta):
	if dragging:
		# The Manager handles z_index and state, 
		# we just follow the mouse
		global_position = get_global_mouse_position()

func _check_drop():
	var in_shaker = false
	var areas = get_overlapping_areas()
	
	for area in areas:
		if area.is_in_group("shaker"):
			area.add_ingredient(ingredient_name)
			in_shaker = true
			break
	
	_return_to_shelf()

func _return_to_shelf():
	if active_tween:
		active_tween.kill()
	
	active_tween = create_tween().set_parallel(true)
	active_tween.tween_property(self, "global_position", start_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "scale", initial_scale, 0.2)
	active_tween.tween_property(self, "rotation", 0.0, 0.2)
