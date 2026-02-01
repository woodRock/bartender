extends Control

signal next_shift_requested

@onready var background = $ColorRect
@onready var score_label = $Panel/CenterContainer/VBoxContainer/ScoreLabel
@onready var orders_label = $Panel/CenterContainer/VBoxContainer/OrdersLabel
@onready var missed_label = $Panel/CenterContainer/VBoxContainer/MissedLabel

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

func _on_next_shift_button_pressed() -> void:
	get_tree().paused = false
	background.hide()
	hide()
	next_shift_requested.emit()
