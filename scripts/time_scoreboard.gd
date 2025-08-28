# ------------------------------------------------------------
# time_scoreboard.gd — Табло времени матча
# Отвечает за:
#   - Отображение времени матча
#   - Обновление UI при изменении времени
#   - Интеграция с MatchTimer
# ------------------------------------------------------------

extends Control
class_name TimeScoreboard

@export var controller_path: NodePath
@onready var controller: Node = get_node_or_null(controller_path)

@onready var time_label: Label = $TimeLabel
@onready var period_label: Label = $PeriodLabel

var match_timer: Node

func _ready() -> void:
	# Создаем таймер матча
	match_timer = preload("res://scripts/match_timer.gd").new()
	add_child(match_timer)
	
	# Подключаем сигналы
	match_timer.time_updated.connect(_on_time_updated)
	match_timer.period_changed.connect(_on_period_changed)
	match_timer.first_half_ended.connect(_on_first_half_ended)
	
	# Инициализируем отображение
	_update_display()
	print("TimeScoreboard: Инициализирован")

func _call_start_match() -> void:
	"""Вызывает start_match() или start_next_half() у контроллера, если он существует"""
	if controller:
		if controller.has_method("start_match"):
			controller.start_match()
		elif controller.has_method("start_next_half"):
			controller.start_next_half()
		else:
			push_warning("TimeScoreboard: controller не имеет методов start_match или start_next_half")
	else:
		push_warning("TimeScoreboard: controller не найден по пути %s" % controller_path)

func start_match() -> void:
	"""Запуск матча"""
	print("TimeScoreboard: Запуск матча")
	_call_start_match()
	match_timer.start_match()
	Audio.play("Sudia", Vector2.ZERO, -6.0, 0.0, 0.0, 0.8)

func _start_match_timer_only() -> void:
	"""Запуск только таймера матча (без вызова контроллера)"""
	print("TimeScoreboard: Запуск только таймера матча")
	match_timer.start_match()

func pause_match() -> void:
	"""Пауза матча"""
	match_timer.pause_match()

func resume_match() -> void:
	"""Возобновление матча"""
	match_timer.resume_match()

func stop_match() -> void:
	"""Остановка матча"""
	Audio.play("Sudia", Vector2.ZERO, -6.0, 0.0, 0.0, 0.8)
	match_timer.stop_match()

func reset_match() -> void:
	"""Сброс матча"""
	match_timer.reset_match()

func start_second_half() -> void:
	"""Запуск второго тайма"""
	match_timer.start_second_half()

func _on_time_updated(_minutes: int, _seconds: int, _period: int) -> void:
	"""Обработчик обновления времени"""
	print("TimeScoreboard: Получил обновление времени")
	_update_display()

func _on_period_changed(_period: int) -> void:
	"""Обработчик смены периода"""
	print("TimeScoreboard: Получил смену периода")
	_update_display()

func _on_first_half_ended() -> void:
	"""Обработчик окончания первого тайма"""
	print("TimeScoreboard: Первый тайм завершен")
	_update_display()
	Audio.play("Sudia", Vector2.ZERO, -6.0, 0.0, 0.0, 0.8)

func _update_display() -> void:
	"""Обновление отображения времени"""
	if time_label:
		var time_string = match_timer.get_time_string()
		time_label.text = time_string
		print("TimeScoreboard: Обновил время на ", time_string)
	
	if period_label:
		var period_string = match_timer.get_period_string()
		period_label.text = period_string
		print("TimeScoreboard: Обновил период на ", period_string)

func get_match_timer() -> Node:
	"""Возвращает таймер матча"""
	return match_timer
