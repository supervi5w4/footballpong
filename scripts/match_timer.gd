# ------------------------------------------------------------
# match_timer.gd — Таймер футбольного матча
# Отвечает за:
#   - Отсчет времени матча (0-90 минут)
#   - Ускорение времени (180x)
#   - Переключение между таймами
#   - Обновление UI табло
# ------------------------------------------------------------

extends Node
class_name MatchTimer

signal time_updated(minutes: int, seconds: int, period: int)
signal period_changed(period: int)
signal match_ended()

# --- Константы ---
const REAL_SECONDS_PER_PERIOD: float = 15.0  # 15 секунд реального времени на тайм
const GAME_MINUTES_PER_PERIOD: int = 45      # 45 минут игрового времени на тайм
const SPEED_MULTIPLIER: float = GAME_MINUTES_PER_PERIOD / REAL_SECONDS_PER_PERIOD  # 180x

# --- Переменные ---
var _real_time_elapsed: float = 0.0
var _current_period: int = 1  # 1 = первый тайм, 2 = второй тайм
var _is_running: bool = false
var _is_paused: bool = false
var _last_displayed_seconds: int = -1  # Для отслеживания изменений времени

# --- Свойства для UI ---
var display_minutes: int = 0
var display_seconds: int = 0
var display_period: int = 1

func _ready() -> void:
	# Подключаем к процессу для обновления времени
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not _is_running or _is_paused:
		return
	
	_real_time_elapsed += delta
	_update_display_time()

func start_match() -> void:
	"""Запуск матча"""
	_real_time_elapsed = 0.0
	_current_period = 1
	_is_running = true
	_is_paused = false
	_last_displayed_seconds = -1
	_update_display_time()
	print("Match started - Period 1")

func pause_match() -> void:
	"""Пауза матча"""
	_is_paused = true
	print("Match paused")

func resume_match() -> void:
	"""Возобновление матча"""
	_is_paused = false
	print("Match resumed")

func stop_match() -> void:
	"""Остановка матча"""
	_is_running = false
	_is_paused = false
	print("Match stopped")

func reset_match() -> void:
	"""Сброс матча"""
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
	"""Обновление отображаемого времени"""
	var total_game_seconds = _real_time_elapsed * SPEED_MULTIPLIER
	
	# Проверяем окончание матча (90 минут)
	if total_game_seconds >= GAME_MINUTES_PER_PERIOD * 2 * 60:
		_is_running = false
		match_ended.emit()
		print("Match ended")
		return
	
	# Определяем период и время для отображения
	if total_game_seconds < GAME_MINUTES_PER_PERIOD * 60:
		# Первый тайм (0-45 минут)
		if _current_period != 1:
			_current_period = 1
			period_changed.emit(_current_period)
			print("Period 1 started")
		
		# Время первого тайма (0-45 минут)
		display_minutes = int(total_game_seconds) / 60
		display_seconds = int(total_game_seconds) % 60
		display_period = 1
	else:
		# Второй тайм (45-90 минут)
		if _current_period != 2:
			_current_period = 2
			period_changed.emit(_current_period)
			print("Period 2 started")
		
		# Время второго тайма (45-90 минут)
		display_minutes = int(total_game_seconds) / 60
		display_seconds = int(total_game_seconds) % 60
		display_period = 2
	
	# Отладочная информация (каждые 30 секунд игрового времени)
	if int(total_game_seconds) % 30 == 0 and int(total_game_seconds) > 0:
		print("Game time: %02d:%02d (Period %d) - Real time: %.1f sec" % [
			display_minutes, display_seconds, display_period, _real_time_elapsed
		])
	
	# Отправляем сигнал об обновлении времени (каждую секунду игрового времени)
	var current_total_seconds = int(total_game_seconds)
	if current_total_seconds != _last_displayed_seconds:
		_last_displayed_seconds = current_total_seconds
		time_updated.emit(display_minutes, display_seconds, display_period)

func get_time_string() -> String:
	"""Возвращает время в формате строки MM:SS"""
	return "%02d:%02d" % [display_minutes, display_seconds]

func get_period_string() -> String:
	"""Возвращает номер периода в виде строки"""
	return str(display_period)

func is_match_running() -> bool:
	"""Проверяет, идет ли матч"""
	return _is_running and not _is_paused

func is_match_paused() -> bool:
	"""Проверяет, стоит ли матч на паузе"""
	return _is_paused

func get_current_period() -> int:
	"""Возвращает текущий период"""
	return _current_period
