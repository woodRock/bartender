extends Area2D

# 1. The Export Variables
@export var ingredient_name: String = "Vodka"
@export var bottle_texture: Texture2D:
	set(value):
		bottle_texture = value
		# This updates the sprite visually in the editor and at runtime
		if is_node_ready():
			$Sprite2D.texture = value

var dragging = false
var start_pos: Vector2
var mouse_offset: Vector2

func _ready():
	start_pos = global_position
	# Apply the texture on start if it was set in inspector
	if bottle_texture:
		$Sprite2D.texture = bottle_texture

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			mouse_offset = global_position - get_global_mouse_position()
			z_index = 10 
		else:
			dragging = false
			z_index = 0
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
	
	# Return to shelf with a snappy animation
	var tween = create_tween()
	tween.tween_property(self, "global_position", start_pos, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
