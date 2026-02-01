extends Resource
class_name IngredientData

@export var name: String = "Unknown"
@export_enum("Spirit", "Liqueur", "Mixer", "Ingredient", "Garnish") var type: String = "Spirit"
@export var texture: Texture2D
@export var color: Color = Color.WHITE
@export var initial_scale: Vector2 = Vector2(1, 1)
@export var is_can: bool = false
@export var is_solid: bool = false # True for Ice/Garnishes
@export var density: int = 1
