# ------------------------------------------------------------
#  scoreboard.gd – табло: названия, счёт и ДВА тайма
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Control

# --- редактируемые параметры -------------------------------------------------
@export var half_duration_real : float = 15.0   # секунд реального времени на 1-й тайм
@export var half_minutes       : float = 45.0   # футбольных минут в одном тайме

# --- состояние ----------------------------------------------------------------
var _elapsed_time       : float = 0.0
var _running            : bool  = false
var _current_half       : int   = 1            # 1 или 2
var _total_minutes_offs : float = 0.0          # 0 для 1-го тайма, 45 для 2-го

# --- ссылки на Label-узлы -----------------------------------------------------
@onready var _lbl_name_left  : Label = $NameLeft
@onready var _lbl_name_right : Label = $NameRight
@onready var _lbl_score_left : Label = $ScoreLeft
@onready var _lbl_score_right: Label = $ScoreRight
@onready var _lbl_time_top   : Label = $TimeTop
@onready var _lbl_time_bottom: Label = $TimeBottom

# -----------------------------------------------------------------------------  
#                       П У Б Л И Ч Н Ы Й   A P I
# -----------------------------------------------------------------------------
func set_team_names(left_name : String, right_name : String) -> void:
	_lbl_name_left.text  = left_name
	_lbl_name_right.text = right_name

func set_scores(left_score : int, right_score : int) -> void:
	_lbl_score_left.text  = str(left_score)
	_lbl_score_right.text = str(right_score)

## Запуск первого тайма
func start_first_half() -> void:
	_start_half(1)

## Запуск второго тайма
func start_second_half() -> void:
	_start_half(2)

## Остановка таймера (например, на паузу)
func stop_timer() -> void:
	_running = false

# -----------------------------------------------------------------------------  
#                            Ж И З Н Е Н Н Ы Й   Ц И К Л
# -----------------------------------------------------------------------------
func _process(delta : float) -> void:
	if _running:
		_elapsed_time += delta
		_update_time_display()
		if _elapsed_time >= half_duration_real:
			# тайм закончился, «фиксируем» значение и останавливаемся
			_elapsed_time = half_duration_real
			_running      = false
			emit_signal("half_finished", _current_half)

# -----------------------------------------------------------------------------  
#                              В С П О М О Г А Т Е Л Ь Н Ы Е
# -----------------------------------------------------------------------------
signal half_finished(half : int)

func _start_half(n : int) -> void:
	_current_half       = n
	_total_minutes_offs = half_minutes * float(n - 1)   # 0 для 1-го, 45 для 2-го
	_elapsed_time       = 0.0
	_running            = true
	_update_time_display()

func _update_time_display() -> void:
	# доля прошедшего реального тайма
	var progress      : float = clamp(_elapsed_time / half_duration_real, 0.0, 1.0)
	# «футбольные» секунды с учётом смещения (0 или 45 мин.)
	var football_secs : float = (_total_minutes_offs * 60.0) + (progress * half_minutes * 60.0)
	var minutes       : int   = int(football_secs) / 60
	var seconds       : int   = int(football_secs) % 60
	var time_text          := "%d:%02d" % [minutes, seconds]

	_lbl_time_top.text    = time_text
	_lbl_time_bottom.text = time_text
