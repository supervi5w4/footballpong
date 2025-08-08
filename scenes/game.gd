# ------------------------------------------------------------
# game.gd — Главный скрипт игровой сцены (Game.tscn)
# Отвечает за:
#   - управление раундами
#   - работу с мячом и ракетками
#   - обновление табло (UI)
# Требует:
#   - Score (Autoload синглтон)
#   - Label-узлы: UI/ScoreLeft и UI/ScoreRight
# ------------------------------------------------------------

extends Node2D
class_name Game

# --- Узлы сцены ---
@onready var ball: RigidBody2D = $Ball
@onready var player_paddle: CharacterBody2D = $PlayerPaddle
@onready var ai_paddle: CharacterBody2D = $AiPaddle

@onready var score_left_label: Label = $UI/ScoreLeft
@onready var score_right_label: Label = $UI/ScoreRight

func _ready() -> void:
	# Подключаемся к сигналу обновления счёта
	Score.score_changed.connect(_update_scoreboard)
	reset_round()

# Обновление табло
func _update_scoreboard(_left: int = 0, _right: int = 0) -> void:
	if score_left_label and score_right_label:
		score_left_label.text = str(Score.left)
		score_right_label.text = str(Score.right)

# Сброс раунда: позиции мяча и ракеток
func reset_round() -> void:
	if ball:
		ball.respawn()

	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()

	_update_scoreboard()
