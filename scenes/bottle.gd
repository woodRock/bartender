extends Area2D

@export var ingredient_name: String = "Vodka"
@export var bottle_texture: Texture2D:
	set(value):
		bottle_texture = value
		# We call the update function here so it changes in the editor too!
		_update_bottle_visuals()

var dragging = false
var start_pos: Vector2
var active_tween: Tween

func _ready():
	start_pos = global_position
	add_to_group("draggables")
	_update_bottle_visuals()

func _update_bottle_visuals():
	# Check if the Sprite node exists yet (prevents errors on startup)
	var sprite = get_node_or_null("Sprite2D")
	if sprite and bottle_texture:
		sprite.texture = bottle_texture
		
		# RE-ALIGNMENT LOGIC:
		# If the sprite is set to 'Centered', its middle is at (0,0).
		# We move the offset down by half the height to put the bottom at (0,0).
		if sprite.centered:
			sprite.offset.y = -bottle_texture.get_height() / 2.0
		else:
			# If you unchecked 'Centered', offset should just be the full height
			sprite.offset.y = -bottle_texture.get_height()

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position()
		var tilt = 45.0 if global_position.x > start_pos.x else -45.0
		rotation = lerp_angle(rotation, deg_to_rad(tilt), 0.1)

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
	active_tween.tween_property(self, "global_position", start_pos, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	active_tween.tween_property(self, "rotation", 0.0, 0.2)
