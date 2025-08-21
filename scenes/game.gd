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

# --- Константы ---
const RETURN_SCENE := "res://scenes/menu.tscn"

# --- Узлы сцены ---
@onready var ball: RigidBody2D = $Ball
@onready var player_paddle: CharacterBody2D = $PlayerPaddle
@onready var ai_paddle: CharacterBody2D = $AiPaddle

@onready var score_left_label: Label = $UI/ScoreLeft
@onready var score_right_label: Label = $UI/ScoreRight
@onready var time_scoreboard: TimeScoreboard = $UI/TimeScoreboard
@onready var message_label: Label = $UI/MessageLabel

var _game_started: bool = false

func _ready() -> void:
	# Сбрасываем счёт в начале игры
	Score.reset_score()
	
	# Подключаемся к сигналу обновления счёта
	Score.score_changed.connect(_update_scoreboard)
	
	# Проверяем, используется ли режим турнира (есть отдельный контроллер)
	var in_tournament: bool = (get_node_or_null("TournamentController") != null)
	
	# Подключаемся к сигналам таймера только в обычном режиме
	if time_scoreboard:
		var match_timer = time_scoreboard.get_match_timer()
		if match_timer and not in_tournament:
			match_timer.first_half_ended.connect(_on_first_half_ended)
			match_timer.match_ended.connect(_on_match_ended)
	
	# Запускаем аналитику игрового процесса
	if YandexSDK.is_working():
		YandexSDK.gameplay_started()
		_game_started = true
	
	# Запускаем таймер матча и сбрасываем позиции только вне турнира.
	# В режиме турнира это делает TournamentController.
	if not in_tournament:
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

# Запуск матча
func start_match() -> void:
	"""Публичный интерфейс для запуска матча"""
	reset_round()

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

# Возврат в главное меню после быстрого матча
func _return_to_menu() -> void:
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(RETURN_SCENE)

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

# Обработчик окончания матча
func _on_match_ended() -> void:
	"""Обработчик окончания матча"""
	print("Game: Матч завершен")
	
	# Показываем надпись "Матч окончен" на 3 секунды
	if message_label:
		message_label.text = "Матч окончен"
		message_label.visible = true
	
	# Ждем 3 секунды
	await get_tree().create_timer(3.0).timeout
	
	# Скрываем надпись
	if message_label:
		message_label.visible = false
	
	# Возвращаемся в главное меню
	_return_to_menu()
