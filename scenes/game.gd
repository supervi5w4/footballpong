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

var _game_started: bool = false

func _ready() -> void:
	# Подключаемся к сигналу обновления счёта
	Score.score_changed.connect(_update_scoreboard)
	
	# Запускаем аналитику игрового процесса
	if YandexSDK.is_working():
		YandexSDK.gameplay_started()
		_game_started = true
	
	reset_round()

func _exit_tree() -> void:
	# Останавливаем аналитику игрового процесса при выходе
	if YandexSDK.is_working() and _game_started:
		YandexSDK.gameplay_stopped()

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

# Функция для показа рекламы между матчами
func show_interstitial_between_matches() -> void:
	YandexSDK.show_interstitial_between_matches()
