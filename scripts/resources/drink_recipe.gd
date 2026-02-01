extends Resource
class_name DrinkRecipe

@export var drink_name: String = ""
@export_multiline var ingredients: Array[String] = []
@export_range(1, 5) var difficulty: int = 1 # 1 = Easy, 5 = Master Mixologist
@export var base_time_limit: float = 45.0 # Seconds given to complete
@export var icon: Texture2D # Optional: for the docket visual
