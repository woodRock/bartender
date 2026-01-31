extends Area2D

@export var ingredient_name: String = "Ice"
@export var item_texture: Texture2D:
	set(value):
		item_texture = value
		if is_node_ready():
			$IngredientIcon.texture = value

var dragging = false
var start_pos: Vector2
var mouse_offset: Vector2
var initial_scale: Vector2

func _ready():
	start_pos = global_position
	if item_texture:
		$IngredientIcon.texture = item_texture
	initial_scale = scale

func _input_event(_viewport, event, _shape_idx):
	var previous_scale: Vector2 = scale
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			mouse_offset = global_position - get_global_mouse_position()
			# Pop up
			create_tween().tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_SINE)
			z_index = 10 
		else:
			# This part triggers when you let go of the mouse
			dragging = false
			z_index = 0
			# Shrink back down immediately on release
			create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
			_check_drop()

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() + mouse_offset

func _check_drop():
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("shaker"):
			area.add_ingredient(ingredient_name)
			break
	
	# Create ONE tween to handle both position and scale reset
	var tween = create_tween().set_parallel(true) # Runs properties at the same time
	tween.tween_property(self, "global_position", start_pos, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", initial_scale, 0.2)
