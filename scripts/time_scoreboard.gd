# ------------------------------------------------------------
# time_scoreboard.gd — Табло времени матча
# Отвечает за:
#   - Отображение времени матча
#   - Обновление UI при изменении времени
#   - Интеграция с MatchTimer
# ------------------------------------------------------------

extends Control
class_name TimeScoreboard

@onready var time_label: Label = $TimeLabel
@onready var period_label: Label = $PeriodLabel

var match_timer: MatchTimer

func _ready() -> void:
	# Создаем таймер матча
	match_timer = MatchTimer.new()
	add_child(match_timer)
	
	# Подключаем сигналы
	match_timer.time_updated.connect(_on_time_updated)
	match_timer.period_changed.connect(_on_period_changed)
	
	# Инициализируем отображение
	_update_display()
	print("TimeScoreboard: Инициализирован")

func start_match() -> void:
	"""Запуск матча"""
	print("TimeScoreboard: Запуск матча")
	match_timer.start_match()

func pause_match() -> void:
	"""Пауза матча"""
	match_timer.pause_match()

func resume_match() -> void:
	"""Возобновление матча"""
	match_timer.resume_match()

func stop_match() -> void:
	"""Остановка матча"""
	match_timer.stop_match()

func reset_match() -> void:
	"""Сброс матча"""
	match_timer.reset_match()

func _on_time_updated(_minutes: int, _seconds: int, _period: int) -> void:
	"""Обработчик обновления времени"""
	print("TimeScoreboard: Получил обновление времени")
	_update_display()

func _on_period_changed(_period: int) -> void:
	"""Обработчик смены периода"""
	print("TimeScoreboard: Получил смену периода")
	_update_display()

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

func get_match_timer() -> MatchTimer:
	"""Возвращает таймер матча"""
	return match_timer
