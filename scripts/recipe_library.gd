extends Resource
class_name RecipeLibrary

@export var all_recipes: Array[DrinkRecipe] = [
	preload("res://resources/drinks/vodka_coke.tres"),
	preload("res://resources/drinks/vodka_soda_lime.tres"),
	preload("res://resources/drinks/vodka_cranberry.tres"),
	preload("res://resources/drinks/black_russian.tres"),
	preload("res://resources/drinks/screwdriver.tres"),
	preload("res://resources/drinks/whiskey_coke.tres"),  
	preload("res://resources/drinks/whiskey_ginger_ale.tres"), 
	preload("res://resources/drinks/whiskey_on_the_rocks.tres"),
	preload("res://resources/drinks/mohito.tres"),
	preload("res://resources/drinks/long_island_ice_tea.tres"),
	preload("res://resources/drinks/espresso_martini.tres"),
	preload("res://resources/drinks/martini.tres"),
	preload("res://resources/drinks/baby_guiness.tres")
]

func get_recipes_by_difficulty(max_difficulty: int) -> Array[DrinkRecipe]:
	var valid_drinks: Array[DrinkRecipe] = []
	for recipe in all_recipes:
		if recipe.difficulty <= max_difficulty:
			valid_drinks.append(recipe)
	return valid_drinks
