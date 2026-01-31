extends Node

# This is where you plug in the Library Resource we created earlier
@export var library: RecipeLibrary 

# A helper function so other nodes can ask for a random drink
func get_random_drink(current_difficulty: int) -> DrinkRecipe:
	var possible_drinks = library.get_recipes_by_difficulty(current_difficulty)
	return possible_drinks.pick_random()

# A helper to check if a player's mix is correct
func check_recipe(drink_name: String, player_ingredients: Array) -> bool:
	for recipe in library.all_recipes:
		if recipe.drink_name == drink_name:
			# Sort both lists so the order of pouring doesn't matter
			var required = recipe.ingredients.duplicate()
			required.sort()
			var provided = player_ingredients.duplicate()
			provided.sort()
			return required == provided
	return false
