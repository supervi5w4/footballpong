# ------------------------------------------------------------
# game.gd — Главный скрипт игровой сцены (Game.tscn)
# Отвечает за:
#   - управление раундами
#   - работу с мячом и ракетками
#   - обновление табло (UI)
#   - управление временем матча
# Требует:
#   - Score (Autoload синглтон)
#   - Label-узлы: UI/ScoreLeft и UI/ScoreRight
#   - TimeScoreboard: UI/TimeScoreboard
# ------------------------------------------------------------

extends Node2D
class_name Game

# --- Узлы сцены ---
@onready var ball: RigidBody2D = $Ball
@onready var player_paddle: CharacterBody2D = $PlayerPaddle
@onready var ai_paddle: CharacterBody2D = $AiPaddle

@onready var score_left_label: Label = $UI/ScoreLeft
@onready var score_right_label: Label = $UI/ScoreRight
@onready var time_scoreboard: TimeScoreboard = $UI/TimeScoreboard

var _game_started: bool = false

func _ready() -> void:
	# Подключаемся к сигналу обновления счёта
	Score.score_changed.connect(_update_scoreboard)
	
	# Подключаемся к сигналу окончания первого тайма
	if time_scoreboard:
		var match_timer = time_scoreboard.get_match_timer()
		if match_timer:
			match_timer.first_half_ended.connect(_on_first_half_ended)
	
	# Запускаем аналитику игрового процесса
	if YandexSDK.is_working():
		YandexSDK.gameplay_started()
		_game_started = true
	
	# Запускаем таймер матча
	if time_scoreboard:
		time_scoreboard.start_match()
	
	reset_round()

func _exit_tree() -> void:
	# Останавливаем аналитику игрового процесса при выходе
	if YandexSDK.is_working() and _game_started:
		YandexSDK.gameplay_stopped()
	
	# Останавливаем таймер матча
	if time_scoreboard:
		time_scoreboard.stop_match()

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

# Пауза матча
func pause_match() -> void:
	if time_scoreboard:
		time_scoreboard.pause_match()

# Возобновление матча
func resume_match() -> void:
	if time_scoreboard:
		time_scoreboard.resume_match()

# Получение таймера матча
func get_match_timer() -> Node:
	if time_scoreboard:
		return time_scoreboard.get_match_timer()
	return null

# Обработчик окончания первого тайма
func _on_first_half_ended() -> void:
	print("Game: Первый тайм завершен, останавливаем игру")
	
	# Останавливаем мяч
	if ball:
		ball.freeze = true
	
	# Показываем сообщение о паузе между таймами
	await get_tree().create_timer(2.0).timeout
	
	# Возвращаем мяч в центр и запускаем второй тайм
	_start_second_half()

func _start_second_half() -> void:
	"""Запуск второго тайма с возвратом мяча в центр"""
	print("Game: Запуск второго тайма")
	
	# Размораживаем мяч перед сбросом
	if ball:
		ball.freeze = false
	
	# Запускаем второй тайм
	if time_scoreboard:
		time_scoreboard.start_second_half()
	
	# Только сбрасываем позиции ракеток, НЕ трогаем мяч
	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
	
	# Мяч уже в центре после заморозки, просто запускаем его
	if ball:
		ball._teleport_to_spawn()
		ball._serve()
	
	print("Game: Второй тайм начался")
