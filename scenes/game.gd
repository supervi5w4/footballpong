# ------------------------------------------------------------
# game.gd — Главный скрипт игровой сцены (Game.tscn)
# Отвечает за:
#   - управление раундами
#   - работу с мячом и ракетками
#   - обновление табло (UI)
#   - управление временем матча
#   - динамическое позиционирование поля и стен
# Требует:
#   - Score (Autoload синглтон)
#   - Label-узлы: UI/ScoreLeft и UI/ScoreRight
#   - TimeScoreboard: UI/TimeScoreboard
# ------------------------------------------------------------

extends Node2D
class_name Game

# --- Константы ---
const RETURN_SCENE := "res://scenes/menu.tscn"

# --- Константы для позиционирования (базовые для 1920x1080) ---
const BASE_FIELD_POSITION := Vector2(962, 533)
const BASE_FIELD_SCALE := Vector2(1.25651, 1.14258)
const BASE_WALL_TOP_POS := Vector2(956, 132)
const BASE_WALL_BOTTOM_POS := Vector2(959.5, 954.5)
const BASE_WALL_LEFT_POS := Vector2(33.75, 534.25)
const BASE_WALL_RIGHT_POS := Vector2(1811, 532.5)
const BASE_WALL_RIGHT2_POS := Vector2(1677, 700.5)
const BASE_WALL_RIGHT3_POS := Vector2(1679, 356.438)
const BASE_WALL_LEFT2_POS := Vector2(85.875, 367.125)
const BASE_WALL_LEFT3_POS := Vector2(86, 699)
const BASE_GOAL_RIGHT_POS := Vector2(1673.25, 531.5)
const BASE_GOAL_LEFT_POS := Vector2(93.3764, 532.241)
const BASE_SPAWN_POS := Vector2(880, 529)
const BASE_PLAYER_PADDLE_POS := Vector2(276, 531)
const BASE_AI_PADDLE_POS := Vector2(1486, 529)

# --- Узлы сцены ---
#@onready var ball: RigidBody2D = $CanvasLayer/Ball
#@onready var player_paddle: CharacterBody2D = $CanvasLayer/PlayerPaddle
#@onready var ai_paddle: CharacterBody2D = $CanvasLayer/AiPaddle
#@onready var field: Sprite2D = $CanvasLayer/Field
#@onready var walls: Node2D = $CanvasLayer/Walls
#@onready var goal_area_right: Area2D = $CanvasLayer/GoalAreaRight
#@onready var goal_area_left: Area2D = $CanvasLayer/GoalAreaLeft
#@onready var spawn_point: Marker2D = $CanvasLayer/SpawnPoint
#@onready var field_controller: FieldController = $CanvasLayer/FieldController

@onready var ball: RigidBody2D = $Ball
@onready var player_paddle: CharacterBody2D = $PlayerPaddle
@onready var ai_paddle: CharacterBody2D = $AiPaddle
@onready var field: Sprite2D = $Field
@onready var walls: Node2D = $Walls
@onready var goal_area_right: Area2D = $GoalAreaRight
@onready var goal_area_left: Area2D = $GoalAreaLeft
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var field_controller: FieldController = $FieldController

@onready var score_left_label: Label = $UI/ScoreLeft
@onready var score_right_label: Label = $UI/ScoreRight
@onready var time_scoreboard: TimeScoreboard = $UI/TimeScoreboard
@onready var message_label: Label = $UI/MessageLabel

var _game_started: bool = false
var _viewport_size: Vector2 = Vector2.ZERO
var _scale_factor: Vector2 = Vector2.ONE

func _ready() -> void:
	$Camera2D.make_current()
	# Ждем один кадр для инициализации viewport
	await get_tree().process_frame
	
	# Инициализируем контроллер поля
	if field_controller and field:
		field_controller.set_field_sprite(field)
		field_controller.field_scaled.connect(_on_field_scaled)
	
	# Вычисляем размеры viewport и масштаб
	#_calculate_viewport_scale()
	
	# Позиционируем все элементы относительно нового размера
	#_position_field_elements()
	#_position_ui_elements()
	
	# Сбрасываем счёт в начале игры
	Score.reset_score()
	Score.player_on_left = true  # Игрок начинает слева
	
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

func _calculate_viewport_scale() -> void:
	"""Вычисляет масштаб для адаптации к текущему размеру viewport"""
	var viewport_rect = get_viewport().get_visible_rect()
	_viewport_size = viewport_rect.size
	
	# Базовый размер для которого заданы координаты элементов
	var base_size = Vector2(1920, 1080)
	
	# Вычисляем общий масштаб для позиционирования элементов
	_scale_factor.x = _viewport_size.x / base_size.x
	_scale_factor.y = _viewport_size.y / base_size.y
	
	print("Viewport size: ", _viewport_size)
	print("Scale factor: ", _scale_factor)

func _position_field_elements() -> void:
	"""Позиционирует все элементы поля относительно нового размера viewport"""
	if not walls:
		return
	
	# Позиционирование поля теперь управляется FieldController
	
	# Позиционируем стены
	_position_walls()
	
	# Позиционируем ворота
	goal_area_right.position = _scale_position(BASE_GOAL_RIGHT_POS)
	goal_area_left.position = _scale_position(BASE_GOAL_LEFT_POS)
	
	# Позиционируем точку спавна
	if not spawn_point:
		spawn_point = get_node_or_null("SpawnPoint")
	if spawn_point:
		spawn_point.position = _scale_position(BASE_SPAWN_POS)
	
	# Позиционируем ракетки
	player_paddle.position = _scale_position(BASE_PLAYER_PADDLE_POS)
	ai_paddle.position = _scale_position(BASE_AI_PADDLE_POS)
	
	# Обновляем стартовые позиции ракеток
	if player_paddle.has_method("set_start_position"):
		player_paddle.set_start_position(player_paddle.position)
	if ai_paddle.has_method("set_start_position"):
		ai_paddle.set_start_position(ai_paddle.position)

func _position_walls() -> void:
	"""Позиционирует все стены"""
	var wall_top = walls.get_node_or_null("WallTop")
	var wall_bottom = walls.get_node_or_null("WallBottom")
	var wall_left = walls.get_node_or_null("WallLeft")
	var wall_right = walls.get_node_or_null("WallRight")
	var wall_right2 = walls.get_node_or_null("WallRight2")
	var wall_right3 = walls.get_node_or_null("WallRight3")
	var wall_left2 = walls.get_node_or_null("WallLeft2")
	var wall_left3 = walls.get_node_or_null("WallLeft3")
	
	if wall_top:
		wall_top.position = _scale_position(BASE_WALL_TOP_POS)
	if wall_bottom:
		wall_bottom.position = _scale_position(BASE_WALL_BOTTOM_POS)
	if wall_left:
		wall_left.position = _scale_position(BASE_WALL_LEFT_POS)
	if wall_right:
		wall_right.position = _scale_position(BASE_WALL_RIGHT_POS)
	if wall_right2:
		wall_right2.position = _scale_position(BASE_WALL_RIGHT2_POS)
	if wall_right3:
		wall_right3.position = _scale_position(BASE_WALL_RIGHT3_POS)
	if wall_left2:
		wall_left2.position = _scale_position(BASE_WALL_LEFT2_POS)
	if wall_left3:
		wall_left3.position = _scale_position(BASE_WALL_LEFT3_POS)

func _scale_position(base_position: Vector2) -> Vector2:
	"""Масштабирует позицию относительно центра экрана"""
	var viewport_center = _viewport_size * 0.5
	var base_center = Vector2(1920, 1080) * 0.5
	
	# Вычисляем смещение от центра
	var offset = base_position - base_center
	
	# Применяем масштаб к смещению
	var scaled_offset = offset * _scale_factor
	
	# Возвращаем новую позицию относительно центра нового viewport
	return viewport_center + scaled_offset

func get_field_bounds() -> Rect2:
	"""Возвращает границы игрового поля"""
	var field_rect = Rect2()
	field_rect.position = Vector2(50, 100) * _scale_factor
	field_rect.size = Vector2(_viewport_size.x - 100, _viewport_size.y - 200) * _scale_factor
	return field_rect

func get_goal_positions() -> Dictionary:
	"""Возвращает позиции ворот"""
	return {
		"left": goal_area_left.position,
		"right": goal_area_right.position
	}

func get_spawn_position() -> Vector2:
	"""Возвращает позицию спавна мяча"""
	if not spawn_point:
		spawn_point = get_node_or_null("SpawnPoint")
		if not spawn_point:
			# Если SpawnPoint не найден, возвращаем центр экрана
			return _viewport_size * 0.5
	return spawn_point.position if spawn_point else Vector2.ZERO

func _position_ui_elements() -> void:
	"""Позиционирует UI элементы относительно нового размера viewport"""
	# UI элементы уже используют anchors, поэтому они должны автоматически адаптироваться
	# Но мы можем добавить дополнительную логику если нужно
	
	print("UI elements positioned for viewport size: ", _viewport_size)

func _notification(what: int) -> void:
	"""Обработка системных уведомлений"""
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# При изменении размера окна пересчитываем позиции
		await get_tree().process_frame
		_calculate_viewport_scale()
		_position_field_elements()
		_position_ui_elements()
		print("Window size changed, repositioned field elements")

func _on_field_scaled(new_scale: Vector2, new_position: Vector2) -> void:
	"""Обработчик изменения масштаба поля"""
	print("Field scaled to: ", new_scale, " at position: ", new_position)
	# Здесь можно добавить дополнительную логику при изменении масштаба поля

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
	"""Запуск второго тайма с возвратом мяча в центр и сменой сторон"""
	print("Game: Запуск второго тайма")
	
	# Размораживаем мяч перед сбросом
	if ball:
		ball.freeze = false
	
	# Меняем стороны: игрок переходит на правую сторону
	Score.player_on_left = false
	
	# Переключаем флаги сторон для ракеток
	if player_paddle and player_paddle.has_method("set_defends_right_side"):
		player_paddle.defends_right_side = true
	if ai_paddle and ai_paddle.has_method("set_defends_right_side"):
		ai_paddle.defends_right_side = false
	
	# Меняем стартовые позиции ракеток местами
	if player_paddle and ai_paddle:
		var temp_pos = player_paddle.start_pos
		player_paddle.start_pos = ai_paddle.start_pos
		ai_paddle.start_pos = temp_pos
	
	# Запускаем второй тайм
	if time_scoreboard:
		time_scoreboard.start_second_half()
	
	# Сбрасываем позиции ракеток на новые места
	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
	
	# Мяч уже в центре после заморозки, просто запускаем его
	if ball:
		ball._teleport_to_spawn()
		ball._serve()
	
	print("Game: Второй тайм начался, стороны поменялись")

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
