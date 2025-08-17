# ------------------------------------------------------------
# match_timer.gd — Таймер футбольного матча
# Отвечает за:
#   - Отсчет времени матча (0–90 минут)
#   - Ускорение времени (180x)
#   - Переключение между таймами
#   - Обновление UI табло
# ------------------------------------------------------------

extends Node
class_name MatchTimer

signal time_updated(minutes: int, seconds: int, period: int)
signal period_changed(period: int)
signal first_half_ended()
signal match_ended()

# --- Константы ---
const REAL_SECONDS_PER_PERIOD: float = 15.0    # 15 секунд реального времени на тайм
const GAME_MINUTES_PER_PERIOD: int = 45        # 45 минут игрового времени на тайм
const SPEED_MULTIPLIER: float = (GAME_MINUTES_PER_PERIOD * 60.0) / REAL_SECONDS_PER_PERIOD
# (2700 игровых секунд) / (15 реальных) = 180x

# --- Переменные ---
var _real_time_elapsed: float = 0.0
var _current_period: int = 1   # 1 = первый тайм, 2 = второй тайм
var _is_running: bool = false
var _is_paused: bool = false
var _last_displayed_seconds: int = -1

# --- Свойства для UI ---
var display_minutes: int = 0
var display_seconds: int = 0
var display_period: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not _is_running or _is_paused:
		return

	_real_time_elapsed += delta
	_update_display_time()

func start_match() -> void:
	_real_time_elapsed = 0.0
	_current_period = 1
	_is_running = true
	_is_paused = false
	_last_displayed_seconds = -1
	_update_display_time()
	print("Match started - Period 1")

func start_second_half() -> void:
	"""Запуск второго тайма"""
	_is_running = true
	_is_paused = false
	_last_displayed_seconds = -1
	period_changed.emit(_current_period)
	print("Second half started")

func pause_match() -> void:
	_is_paused = true
	print("Match paused")

func resume_match() -> void:
	_is_paused = false
	print("Match resumed")

func stop_match() -> void:
	_is_running = false
	_is_paused = false
	print("Match stopped")

func reset_match() -> void:
	_real_time_elapsed = 0.0
	_current_period = 1
	_is_running = false
	_is_paused = false
	display_minutes = 0
	display_seconds = 0
	display_period = 1
	_last_displayed_seconds = -1
	time_updated.emit(display_minutes, display_seconds, display_period)
	print("Match reset")

func _update_display_time() -> void:
	# Переводим реальное время → игровое
	var total_game_seconds: float = _real_time_elapsed * SPEED_MULTIPLIER

	# Проверка конца матча (90 минут = 5400 секунд игрового времени)
	if total_game_seconds >= GAME_MINUTES_PER_PERIOD * 2 * 60:
		# Устанавливаем финальное значение 90:00 перед завершением матча
		display_minutes = GAME_MINUTES_PER_PERIOD * 2
		display_seconds = 0
		display_period = 2
		time_updated.emit(display_minutes, display_seconds, display_period)
		
		_is_running = false
		match_ended.emit()
		print("Match ended")
		return

	# Первый тайм (0–45 минут)
	if total_game_seconds < GAME_MINUTES_PER_PERIOD * 60:
		if _current_period != 1:
			_current_period = 1
			period_changed.emit(_current_period)
			print("Period 1 started")

		display_minutes = int(total_game_seconds / 60)
		display_seconds = int(total_game_seconds) % 60
		display_period = 1

	# Проверка окончания первого тайма (45 минут)
	elif total_game_seconds >= GAME_MINUTES_PER_PERIOD * 60 and _current_period == 1:
		# Устанавливаем финальное значение первого тайма 45:00
		display_minutes = GAME_MINUTES_PER_PERIOD
		display_seconds = 0
		display_period = 1
		time_updated.emit(display_minutes, display_seconds, display_period)
		
		_is_running = false
		_current_period = 2
		first_half_ended.emit()
		print("First half ended")
		return

	# Второй тайм (45–90 минут)
	else:
		if _current_period != 2:
			_current_period = 2
			period_changed.emit(_current_period)
			print("Period 2 started")

		display_minutes = int(total_game_seconds / 60)
		display_seconds = int(total_game_seconds) % 60
		display_period = 2

	# Отправляем сигнал каждую игровую секунду
	var current_total_seconds = int(total_game_seconds)
	if current_total_seconds != _last_displayed_seconds:
		_last_displayed_seconds = current_total_seconds
		time_updated.emit(display_minutes, display_seconds, display_period)

func get_time_string() -> String:
	return "%02d" % [display_minutes]

func get_period_string() -> String:
	return str(display_period)

func is_match_running() -> bool:
	return _is_running and not _is_paused

func is_match_paused() -> bool:
	return _is_paused

func get_current_period() -> int:
	return _current_period
