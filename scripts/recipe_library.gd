extends Resource
class_name RecipeLibrary

@export var all_recipes: Array[DrinkRecipe] = [
	preload("res://resources/drinks/vodka_coke.tres"),
	preload("res://resources/drinks/mohito.tres"),
	preload("res://resources/drinks/long_island_ice_tea.tres")
]

func get_recipes_by_difficulty(max_difficulty: int) -> Array[DrinkRecipe]:
	var valid_drinks: Array[DrinkRecipe] = []
	for recipe in all_recipes:
		if recipe.difficulty <= max_difficulty:
			valid_drinks.append(recipe)
	return valid_drinks
