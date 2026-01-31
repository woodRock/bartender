extends Control

@onready var background = $ColorRect
@onready var score_label = $Panel/VBoxContainer/ScoreLabel
@onready var orders_label = $Panel/VBoxContainer/OrdersLabel
@onready var missed_label = $Panel/VBoxContainer/MissedLabel

func _ready():
	background.hide()
	hide() # Start hidden

func show_summary(total_score: int, completed: int, missed: int):
	score_label.text = "Total Tips: $" + str(total_score)
	orders_label.text = "Drinks Served: " + str(completed)
	missed_label.text = "Lost Customers: " + str(missed)
	
	background.show()
	show()
	# Optional: Pause the game world while looking at results
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
