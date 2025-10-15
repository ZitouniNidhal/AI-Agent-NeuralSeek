extends Node

@onready var score_label: Label = $UI/ScoreLabel
var score: int = 0

func _ready():
	start_game()

func start_game():
	score = 0
	update_ui()

func update_ui():
	score_label.text = "Score: " + str(score)

func add_score(points: int):
	score += points
	update_ui()