extends Node2D

# --- Configuration ---
@export var ingredient_item_scene: PackedScene

# --- Folder Paths ---
@export_dir var spirits_folder: String = "res://resources/spirits/"
@export_dir var mixers_folder: String = "res://resources/mixers/"
@export_dir var ingredients_folder: String = "res://resources/ingredients/"
@export_dir var liqueurs_folder: String = "res://resources/liqueurs/"

# --- Anchor Points ---
@onready var spirit_anchor = $SpiritsAnchor
@onready var mixer_anchor = $MixersAnchor
@onready var ingredient_center = $IngredientsAnchor
@onready var liqueurs_anchor = $LiqueursAnchor

# --- Layout Settings ---
@export var spirit_columns: int = 2
@export var spirit_spacing: Vector2 = Vector2(80, 100)
@export var mixer_spacing: float = 70.0

@export var circle_radius: float = 100.0
@export var circle_rotation_offset: float = -90.0 # Starts at 12 o'clock

func _ready():
	_load_and_spawn()

func _load_and_spawn():
	_spawn_spirit_grid(_get_resources(spirits_folder))
	_spawn_liqueurs_grid(_get_resources(liqueurs_folder))
	_spawn_mixer_line(_get_resources(mixers_folder))
	_spawn_ingredient_circle(_get_resources(ingredients_folder))

# --- Spirit Grid Logic (Two Vertical Columns) ---
func _spawn_spirit_grid(data_list: Array):
	for i in range(data_list.size()):
		var item = _instantiate_item(data_list[i], spirit_anchor)
		var column = i % spirit_columns
		var row = i / spirit_columns
		item.position = Vector2(column * spirit_spacing.x, row * spirit_spacing.y)
		item.start_pos = item.global_position
		
# --- Spirit Grid Logic (Two Vertical Columns) ---
func _spawn_liqueurs_grid(data_list: Array):
	for i in range(data_list.size()):
		var item = _instantiate_item(data_list[i], liqueurs_anchor)
		var column = i % spirit_columns
		var row = i / spirit_columns
		item.position = Vector2(column * spirit_spacing.x, row * spirit_spacing.y)
		item.start_pos = item.global_position

# --- Mixer Line Logic (Standard Horizontal) ---
func _spawn_mixer_line(data_list: Array):
	for i in range(data_list.size()):
		var item = _instantiate_item(data_list[i], mixer_anchor)
		item.position = Vector2(i * mixer_spacing, 0)
		item.start_pos = item.global_position

# --- Ingredient Circle & Ice Logic ---
func _spawn_ingredient_circle(data_list: Array):
	var circle_items = []
	var ice_res = null
	var crushed_res = null
	
	# Separate ice resources from the rest
	for res in data_list:
		var n = res.name.to_lower()
		if "crushed" in n: 
			crushed_res = res
		elif "ice" in n: 
			ice_res = res
		else: 
			circle_items.append(res)
	
	var total_count = circle_items.size()
	
	# 1. Position Garnishes in a Full Circle
	for i in range(total_count):
		var item = _instantiate_item(circle_items[i], ingredient_center)
		
		# Calculate angle in radians: (i / total) * 360 degrees
		var angle = (float(i) / total_count) * TAU # TAU is 2*PI
		angle += deg_to_rad(circle_rotation_offset)
		
		# Polar to Cartesian
		var pos = Vector2(cos(angle), sin(angle)) * circle_radius
		
		item.position = pos
		item.start_pos = item.global_position

	# 2. Position Ice in the Sibling "IceWell"
	if ice_res:
		var well = get_parent().get_node_or_null("Bar/IceWell")
		if well is CanvasItem:
			_spawn_at_node(ice_res, well)
		else:
			print("Warning: ShelfManager couldn't find Bar/IceWell or it isn't a CanvasItem")

	# 3. Position Crushed Ice in the Sibling "IceCrusher"
	if crushed_res:
		var crusher = get_parent().get_node_or_null("Bar/IceCrusher")
		if crusher is CanvasItem:
			_spawn_at_node(crushed_res, crusher)
		else:
			print("Warning: ShelfManager couldn't find Bar/IceCrusher or it isn't a CanvasItem")

# --- Helper Functions ---

func _instantiate_item(res: IngredientData, parent_node: Node) -> Area2D:
	var item = ingredient_item_scene.instantiate()
	item.data = res
	parent_node.add_child(item)
	return item

func _spawn_at_node(res: IngredientData, target_node: CanvasItem):
	var item = _instantiate_item(res, target_node)
	
	if target_node is Control:
		item.position = target_node.size / 2
	else:
		item.position = Vector2.ZERO
		
	item.start_pos = item.global_position

func _get_resources(path: String) -> Array:
	var list = []
	if path == "": return list
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				var clean_path = path + "/" + file_name.replace(".remap", "")
				var res = load(clean_path)
				if res is IngredientData:
					list.append(res)
			file_name = dir.get_next()
	return list
