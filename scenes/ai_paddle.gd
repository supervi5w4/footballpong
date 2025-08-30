# ------------------------------------------------------------
# AiPaddle.gd — Advanced AI for Football Pong
# Godot 4.4.1 | GDScript 2.0
# v2.6+ (HIGH_SPEED_DEFEND, EDGE_GUARD, aggression, safety fixes)
# ------------------------------------------------------------
extends CharacterBody2D
class_name AiPaddle

# --- Горизонтальные ограничения (аналогично Player) ---
@export var LEFT_MARGIN_PX: int = 200
@export var use_center_as_right_limit: bool = true
@export var center_bias_px: int = 50     # на сколько пикселей НЕ доходить до центра
@export var half_size_override: Vector2 = Vector2.ZERO

# ---------------- Tunables & Constants ----------------
@export_range(0.0, 1.0, 0.01) var skill: float = 0.85
@export_enum("aggressive", "balanced", "defensive") var behaviour_style: String = "balanced"
@export_range(0.0, 1.0, 0.01) var aggression: float = 0.5  # 0 — сдержанно, 1 — навязчиво
@export_range(0.0, 2.0, 0.1) var spin_influence: float = 1.0  # Влияние спина на предсказание (0 = без спина, 2 = сильное влияние)

@export var ball_path: NodePath
@export var player_path: NodePath
@export var defends_right_side: bool = true

@export var max_bounces: int = 3
@export var wall_bounce_damp: float = 0.9
@export var paddle_bounce_damp: float = 0.8

@export var goal_left: Vector2 = Vector2(0, 540)

const BASE_SPEED: float = 850.0
const REACTION_BASE: float = 0.12
const ATTACK_OFFSET: float = 80.0
const ERROR_BASE_RADIUS: float = 24.0
const FIRST_HIT_DEVIATION_Y: float = 260.0
const ADVANCE_LIMIT_PROPORTION: float = 0.47
const FAST_BALL_SPEED: float = 1700.0
const EDGE_MARGIN: float = 120.0
const STRONG_HIT_SPEED: float = 1800.0
const STRONG_HIT_ANGLE: float = 0.75

const STYLE_DB: Dictionary = {
	"aggressive": {"speed_mul": 1.35, "risk_zone": 0.50, "error_mult": 1.2},
	"balanced":   {"speed_mul": 1.00, "risk_zone": 0.25, "error_mult": 1.0},
	"defensive":  {"speed_mul": 0.85, "risk_zone": 0.12, "error_mult": 0.8},
}

const Utils: Script = preload("res://scripts/utils.gd")

enum State { DEFEND, INTERCEPT, BLOCK_PLAYER, ATTACK, FAKE, DODGE, RETREAT, HIGH_SPEED_DEFEND, EDGE_GUARD }
var _state: State = State.DEFEND

# ---------------- Runtime Variables ----------------
var _ball: RigidBody2D
var _player: CharacterBody2D
var _target_pos: Vector2 = Vector2.ZERO
var _smooth_target_pos: Vector2 = Vector2.ZERO  # Плавная цель для движения
var _time_to_next_think: float = 0.0
var _fake_timer: float = 0.0
var _direction_change_delay: float = 0.0  # Задержка при смене направления для низких навыков
var start_pos: Vector2 = Vector2.ZERO
var _is_first_hit: bool = true
var _smooth_factor: float = 0.15  # Фактор плавности (0.1 = очень плавно, 0.3 = быстро)
var _game_node: Node = null
var _scale_factor: Vector2 = Vector2.ONE

# ---------------- Stuck Detection Variables ----------------
var _stuck_timer: float = 0.0  # Таймер застревания у границ
var _stuck_threshold: float = 0.5  # Порог времени застревания (0.5 секунды)
var _stuck_margin: float = 80.0  # Расстояние от границы для определения застревания
var _emergency_reset_timer: float = 0.0  # Таймер для аварийного сброса
var _emergency_reset_threshold: float = 2.0  # Порог для аварийного сброса (2 секунды)

# ---------------- Player Shot History ----------------
var player_shot_history: Array[float] = []  # История Y-позиций ударов игрока
const MAX_SHOT_HISTORY: int = 5  # Максимальная длина истории
const MIN_SHOT_HISTORY: int = 1  # Минимальная длина истории для низких навыков

# ---------------- Dynamic Field Properties ----------------
func get_field_size() -> Vector2:
	"""Возвращает текущий размер игрового поля из viewport"""
	return get_field_rect().size

func get_half_field_x() -> float:
	"""Возвращает координату X центра поля"""
	var r := get_field_rect()
	return r.position.x + r.size.x * 0.5

func get_goal_right() -> Vector2:
	"""Возвращает позицию правых ворот"""
	var r := get_field_rect()
	return Vector2(r.position.x + r.size.x, r.position.y + r.size.y * 0.5)

# Helper: real field rect and Y clamp
func get_field_rect() -> Rect2:
	if _game_node and _game_node.has_method("get_field_bounds"):
		return _game_node.get_field_bounds()
	var vp := get_viewport_rect()
	return Rect2(vp.position, vp.size)

func _clamp_y_to_field(y: float, margin: float = 80.0) -> float:
	var r := get_field_rect()
	return clamp(y, r.position.y + margin, r.position.y + r.size.y - margin)

# ---------------- READY ----------------
func _ready() -> void:
	_ball = get_node_or_null(ball_path) as RigidBody2D
	_player = get_node_or_null(player_path) as CharacterBody2D
	if _ball == null or _player == null:
		push_error("AiPaddle: ball_path/player_path не назначены.")
		set_physics_process(false)
		return
	start_pos = global_position
	_smooth_target_pos = global_position  # Инициализируем плавную цель
	
	# Находим игровую сцену для получения масштаба
	_find_game_node()
	
	_think()
	_schedule_next_think()

func _find_game_node() -> void:
	"""Находит игровую сцену для получения масштаба"""
	var parent = get_parent()
	while parent and not parent.has_method("get_spawn_position"):
		parent = parent.get_parent()
	_game_node = parent

func _get_scale_factor() -> Vector2:
	"""Получает текущий масштаб от игровой сцены"""
	if _game_node and _game_node.has_method("_calculate_viewport_scale"):
		# Получаем масштаб из игровой сцены
		var viewport_size = get_viewport().get_visible_rect().size
		var base_size = Vector2(1920, 1080)
		return Vector2(viewport_size.x / base_size.x, viewport_size.y / base_size.y)
	return Vector2.ONE

func reset_position() -> void:
	global_position = start_pos
	_smooth_target_pos = start_pos  # Сбрасываем плавную цель
	velocity = Vector2.ZERO
	_state = State.DEFEND
	_time_to_next_think = 0.0
	_fake_timer = 0.0
	_direction_change_delay = 0.0  # Сбрасываем задержку смены направления
	_is_first_hit = true
	# Сбрасываем таймеры застревания
	_stuck_timer = 0.0
	_emergency_reset_timer = 0.0
	# Очищаем историю ударов при сбросе позиции
	player_shot_history.clear()

# ---------------- Player Shot History Functions ----------------
func record_player_shot() -> void:
	"""Записывает Y-позицию мяча при ударе игрока"""
	if _ball:
		player_shot_history.append(_ball.global_position.y)
		
		# Ограничиваем длину истории в зависимости от навыков
		var max_history_length = MIN_SHOT_HISTORY if skill < 0.5 else MAX_SHOT_HISTORY
		
		# Удаляем старые записи, если превышен лимит
		while player_shot_history.size() > max_history_length:
			player_shot_history.pop_front()

func get_average_shot_position() -> float:
	"""Возвращает среднее значение Y-позиций из истории ударов"""
	if player_shot_history.is_empty():
		return 0.0
	
	var sum: float = 0.0
	for shot_y in player_shot_history:
		sum += shot_y
	
	return sum / player_shot_history.size()

func should_use_shot_history() -> bool:
	"""Определяет, следует ли использовать историю ударов"""
	return skill > 0.8 and player_shot_history.size() >= 2

func set_start_position(pos: Vector2) -> void:
	"""Устанавливает новую стартовую позицию ракетки"""
	start_pos = pos
	global_position = pos
	_smooth_target_pos = pos

func set_defends_right_side(value: bool) -> void:
	"""Устанавливает флаг защиты правой стороны поля"""
	defends_right_side = value

# ---------------- MAIN ----------------
func _physics_process(delta: float) -> void:
	# Обновляем масштаб
	_scale_factor = _get_scale_factor()
	
	_time_to_next_think -= delta
	_fake_timer -= delta
	if _time_to_next_think <= 0.0:
		_think()
		_schedule_next_think()
	_move()
	_handle_ball_collisions()
	_check_first_hit_reset()
	_detect_player_shot()

# ------------ Collision & First-hit helpers ------------
func _handle_ball_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var rb := col.get_collider() as RigidBody2D
		if rb and rb.is_in_group("ball"):
			var miss_skip: float = pow(1.0 - skill, 3.0)
			if randf() < miss_skip:
				continue

			var normal: Vector2 = col.get_normal()
			var info: Dictionary = Utils.reflect(rb.linear_velocity, normal, velocity)

			if _is_first_hit:
				var sign_dir: float = sign(rb.global_position.y - _player.global_position.y)
				info["vel"].y += sign_dir * FIRST_HIT_DEVIATION_Y
				_is_first_hit = false

			# Улучшенная логика удара: направляем мяч к воротам противника
			_improve_shot_direction(info, rb.global_position)

			var miss := pow(1.0 - skill, 2.0)
			if randf() < miss:
				var angle_err := randf_range(-0.35, 0.35) * (1.0 + (1.0 - skill))
				info["vel"]  = info["vel"].rotated(angle_err) * lerp(0.5, 1.0, skill)
				info["spin"] = info["spin"] * lerp(0.5, 1.0, skill)

			rb.linear_velocity  = info["vel"]
			rb.angular_velocity = info["spin"]
			# Увеличиваем скорость мяча при ударе
			if rb is Ball:
				rb.boost_speed()
				if Audio:
					Audio.play(
						"kick_1",
						rb.global_position,
						-10.0,   # базовая громкость
						0.05,    # ±5% питч
						3.0,     # ±3 дБ
						0.5      # кулдаун 0.5 c
					)

func _improve_shot_direction(info: Dictionary, ball_pos: Vector2) -> void:
	"""Улучшает направление удара, направляя мяч к воротам противника"""
	# Определяем позицию ворот противника
	var enemy_goal: Vector2
	if defends_right_side:
		enemy_goal = goal_left  # AI защищает правую сторону, цель - левые ворота
	else:
		enemy_goal = get_goal_right()  # AI защищает левую сторону, цель - правые ворота
	
	# Вычисляем вектор от мяча к воротам противника
	var direction_to_goal = (enemy_goal - ball_pos).normalized()
	
	# Сохраняем исходную скорость мяча
	var original_speed = info["vel"].length()
	
	# Заменяем направление на направление к воротам
	info["vel"] = direction_to_goal * original_speed
	
	# Добавляем погрешность в зависимости от навыков
	var error_angle = randf_range(-0.3, 0.3) * (1.0 - skill)  # Больше погрешности для слабого AI
	info["vel"] = info["vel"].rotated(error_angle)
	
	# Улучшаем спин для усиления удара
	var spin_strength = lerp(0.5, 1.5, skill)  # Сильный AI использует больше спина
	var spin_direction = sign(info["vel"].y)  # Спин в направлении движения мяча
	
	# Устанавливаем спин для усиления удара
	info["spin"] = spin_direction * spin_strength * 10.0  # Множитель 10 для заметного эффекта

# ------------ Player Shot Detection ------------
func _detect_player_shot() -> void:
	"""Определяет удар игрока и записывает его в историю"""
	if not _ball or not _player:
		return
	
	# Проверяем, что мяч движется от игрока к AI
	var ball_velocity = _ball.linear_velocity
	var ball_to_ai = (global_position - _ball.global_position).normalized()
	var velocity_toward_ai = ball_velocity.dot(ball_to_ai) > 0.0
	
	# Проверяем, что мяч находится на стороне игрока
	var ball_on_player_side = (defends_right_side and _ball.global_position.x < get_half_field_x()) or \
							 (not defends_right_side and _ball.global_position.x > get_half_field_x())
	
	# Проверяем, что мяч достаточно близко к игроку (возможно, был удар)
	var distance_to_player = _ball.global_position.distance_to(_player.global_position)
	var close_to_player = distance_to_player < 150.0  # Уменьшили порог для более точного определения
	
	# Проверяем, что мяч имеет достаточную скорость (признак удара)
	var ball_speed = ball_velocity.length()
	var sufficient_speed = ball_speed > 400.0
	
	# Если мяч движется к AI с достаточной скоростью и был близко к игроку
	if velocity_toward_ai and ball_on_player_side and close_to_player and sufficient_speed:
		# Записываем удар
		record_player_shot()

func _check_first_hit_reset() -> void:
	if not _is_first_hit:
		var left_side: bool = _ball.global_position.x < get_half_field_x()
		if (defends_right_side and left_side) or (not defends_right_side and not left_side):
			_is_first_hit = true

func _schedule_next_think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	var weak := 1.0 - skill
	# Увеличиваем реакцию в зависимости от (1 - skill)^2 для низких навыков
	var react := REACTION_BASE + pow(weak, 2.0) * 0.6
	react *= randf_range(0.8, 1.4) * float(style.error_mult) * (1.0 + weak)
	# Увеличиваем интервал обновления для более плавного движения
	react *= 1.5  # Увеличили интервал на 50%
	_time_to_next_think = react

# ---------------- THINK ----------------
func _think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	aggression = clamp(aggression, 0.0, 1.0)

	var ball_pos: Vector2 = _ball.global_position
	var player_pos: Vector2 = _player.global_position

	var lv: Vector2 = _ball.linear_velocity
	var spd: float = lv.length()
	var ball_dir: Vector2 = (lv / max(spd, 0.0001))  # безопасная "нормализация"

	var ball_behind: bool = _is_ball_behind()
	var heading_to_goal: bool = (defends_right_side and lv.x > 0.0) or (not defends_right_side and lv.x < 0.0)

	if ball_behind:
		_state = State.DODGE if heading_to_goal else State.RETREAT
		match _state:
			State.DODGE:
				_target_pos = _dodge_pos(ball_pos)
			State.RETREAT:
				_target_pos = _retreat_pos()
	else:
		var toward_player: Vector2 = (player_pos - ball_pos).normalized()
		var toward_me: Vector2 = (global_position - ball_pos).normalized()
		var b_to_player: bool = ball_dir.dot(toward_player) > 0.7
		var b_to_me: bool = ball_dir.dot(toward_me) > 0.7
		var fast_ball: bool = spd > FAST_BALL_SPEED
		var field_size = get_field_size()
		var edge_near: bool = ball_pos.y < EDGE_MARGIN or ball_pos.y > field_size.y - EDGE_MARGIN
		var strong_hit: bool = b_to_me and (spd > STRONG_HIT_SPEED or abs(ball_dir.y) > STRONG_HIT_ANGLE)

		if strong_hit and randf() < 0.5:
			_state = State.DODGE
			_target_pos = _dodge_pos(ball_pos)
		elif fast_ball and heading_to_goal and randf() < 0.8:
			_state = State.HIGH_SPEED_DEFEND
			_target_pos = _high_speed_pos(ball_pos)
		elif edge_near and randf() < 0.6:
			_state = State.EDGE_GUARD
			_target_pos = _edge_guard_pos(ball_pos)
		elif not _is_on_my_side(ball_pos) or not b_to_me:
			_state = State.INTERCEPT
			_target_pos = _predict_multi_bounce(ball_pos, lv, max_bounces)
		else:
			match _state:
				State.DEFEND:
					var block_chance: float = lerp(0.7, 0.2, aggression)
					_state = State.INTERCEPT if b_to_me else State.BLOCK_PLAYER if b_to_player and randf() < block_chance else State.ATTACK
				State.INTERCEPT:
					_state = State.FAKE if randf() < 0.25 else _state
				State.BLOCK_PLAYER:
					if not b_to_player:
						_state = State.ATTACK
				State.FAKE:
					if _fake_timer <= 0.0:
						_state = State.INTERCEPT
				State.ATTACK:
					if b_to_me:
						_state = State.INTERCEPT
					elif b_to_player:
						_state = State.BLOCK_PLAYER
				State.DODGE:
					if not ball_behind:
						_state = State.DEFEND
				State.RETREAT:
					_state = State.DEFEND
				State.HIGH_SPEED_DEFEND:
					if not fast_ball:
						_state = State.DEFEND
				State.EDGE_GUARD:
					if not edge_near:
						_state = State.DEFEND

			match _state:
				State.DEFEND:
					_target_pos = _goal_pos(ball_pos)
				State.INTERCEPT:
					# Используем предсказание с учётом спина для высоких навыков
					if skill > 0.85:
						_target_pos = _predict_intercept_with_spin()
					else:
						_target_pos = _predict_intercept()
				State.BLOCK_PLAYER:
					_target_pos = _block_pos(player_pos)
				State.FAKE:
					_target_pos = ball_pos + Vector2(randf_range(-150.0, 150.0), randf_range(-100.0, 100.0))
					_fake_timer = 0.25
				State.ATTACK:
					_target_pos = _attack_pos(ball_pos)
				State.DODGE:
					_target_pos = _dodge_pos(ball_pos)
				State.RETREAT:
					_target_pos = _retreat_pos()
				State.HIGH_SPEED_DEFEND:
					_target_pos = _high_speed_pos(ball_pos)
				State.EDGE_GUARD:
					_target_pos = _edge_guard_pos(ball_pos)

	_add_error(style)
	_clamp_advancement()
	_clamp_target_x()

# ------------ Helper Calculations ---------------
func _goal_pos(ball_pos: Vector2) -> Vector2:
	var my_goal: Vector2 = get_goal_right() if defends_right_side else goal_left
	var base_pos = my_goal.lerp(ball_pos, 0.25)
	
	# Используем историю ударов для корректировки позиции на высоких навыках
	if should_use_shot_history():
		var avg_shot_y = get_average_shot_position()
		var field_size = get_field_size()
		
		# Смещаем целевую позицию в сторону среднего значения истории
		var history_bias = 0.3  # Сила влияния истории (0.0 - 1.0)
		var target_y = lerp(base_pos.y, avg_shot_y, history_bias)
		
		# Ограничиваем позицию в пределах поля
		target_y = _clamp_y_to_field(target_y)
		
		return Vector2(base_pos.x, target_y)
	
	return base_pos

func _attack_pos(ball_pos: Vector2) -> Vector2:
	var enemy_goal: Vector2 = goal_left if defends_right_side else get_goal_right()
	var y_offset: float = ATTACK_OFFSET * sign(ball_pos.y - _player.global_position.y)
	return (ball_pos + Vector2(0, y_offset)).lerp(enemy_goal, 0.10)

func _block_pos(player_pos: Vector2) -> Vector2:
	var r := get_field_rect()
	var field_size = get_field_size()
	var offset_y: float = 120.0 if player_pos.y < field_size.y * 0.5 else -120.0
	return Vector2(player_pos.x, _clamp_y_to_field(player_pos.y + offset_y))

func _high_speed_pos(ball_pos: Vector2) -> Vector2:
	# Используем предсказание с учётом спина для высоких навыков
	var intercept: Vector2
	if skill > 0.85:
		intercept = _predict_intercept_with_spin()
	else:
		intercept = _predict_intercept()
	return intercept.lerp(_goal_pos(ball_pos), 0.5)

func _edge_guard_pos(ball_pos: Vector2) -> Vector2:
	var r := get_field_rect()
	var mid_y := r.position.y + r.size.y * 0.5
	var top := r.position.y + 80.0
	var bottom := r.position.y + r.size.y - 80.0
	var target_y: float = top if ball_pos.y < mid_y else bottom
	return Vector2(global_position.x, target_y)

func _predict_second_bounce() -> Vector2:
	var r := get_field_rect()
	var wall_x: float = (r.position.x + r.size.x) if defends_right_side else r.position.x
	var from: Vector2 = _ball.global_position
	var vel: Vector2 = _ball.linear_velocity.normalized()
	var dist: float = abs(wall_x - from.x)
	var first_hit: Vector2 = from + vel * dist
	var after_bounce: Vector2 = Vector2(-vel.x, vel.y)
	return first_hit + after_bounce * dist * 0.3

func _predict_multi_bounce(ball_pos: Vector2, velocity: Vector2, max_bounces: int) -> Vector2:
	var r := get_field_rect()
	var pos: Vector2 = ball_pos
	var vel: Vector2 = velocity
	var top: float = r.position.y
	var bottom: float = r.position.y + r.size.y
	var target_x: float = global_position.x
	var player_x: float = _player.global_position.x
	var b: int = 0
	while b < max_bounces:
		var toward_me: bool = (defends_right_side and vel.x > 0.0) or (not defends_right_side and vel.x < 0.0)
		if toward_me:
			var t_to_me: float = (target_x - pos.x) / max(vel.x, 0.0001)
			if t_to_me >= 0.0:
				pos += vel * t_to_me
				return Vector2(target_x, _clamp_y_to_field(pos.y))
		var t_top: float = INF
		var t_bottom: float = INF
		if vel.y < 0.0:
			t_top = (top - pos.y) / vel.y
		elif vel.y > 0.0:
			t_bottom = (bottom - pos.y) / vel.y
		var t_wall: float = min(t_top, t_bottom)
		var toward_player: bool = (defends_right_side and vel.x < 0.0) or (not defends_right_side and vel.x > 0.0)
		var t_player: float = INF
		if toward_player:
			t_player = (player_x - pos.x) / max(vel.x, 0.0001)
			if t_player < 0.0:
				t_player = INF
		var t_next: float = min(t_wall, t_player)
		if t_next == INF:
			break
		pos += vel * t_next
		if t_next == t_wall:
			vel.y = -vel.y * wall_bounce_damp
		else:
			vel.x = -vel.x * paddle_bounce_damp
		b += 1
	if is_zero_approx(vel.x):
		return Vector2(target_x, _clamp_y_to_field(pos.y))
	var t_final: float = (target_x - pos.x) / max(vel.x, 0.0001)
	pos += vel * t_final
return Vector2(target_x, _clamp_y_to_field(pos.y))

# ---------- Prediction / Dodge helpers ----------
func _is_on_my_side(pos: Vector2) -> bool:
	return (defends_right_side and pos.x > get_half_field_x()) or (not defends_right_side and pos.x < get_half_field_x())

func _is_ball_behind() -> bool:
	return (defends_right_side and _ball.global_position.x > global_position.x) or \
		   (not defends_right_side and _ball.global_position.x < global_position.x)

func _predict_intercept() -> Vector2:
	var paddle_x: float = global_position.x
	var p: Vector2 = _ball.global_position
	var v: Vector2 = _ball.linear_velocity
	if is_zero_approx(v.x):
		return p
	var t: float = (paddle_x - p.x) / v.x
	if t < 0.0:
		return p
	var y: float = p.y + v.y * t
	var r := get_field_rect()
	var top: float = r.position.y
	var height: float = r.size.y
	var period: float = height * 2.0
	var local_y: float = fposmod(y - top, period)
	if local_y > height:
		local_y = period - local_y
	var final_y: float = top + local_y
	return Vector2(paddle_x, _clamp_y_to_field(final_y))

func _predict_intercept_with_spin() -> Vector2:
	"""
	Предсказывает точку перехвата мяча с учётом его спина (angular_velocity).
	Спин влияет на траекторию мяча, создавая эффект Магнуса.
	"""
	var paddle_x: float = global_position.x
	var p: Vector2 = _ball.global_position
	var v: Vector2 = _ball.linear_velocity
	var spin: float = _ball.angular_velocity
	
	if is_zero_approx(v.x):
		return p
	
	var t: float = (paddle_x - p.x) / v.x
	if t < 0.0:
		return p
	
	# Базовое предсказание без спина
	var base_y: float = p.y + v.y * t
	
	# Влияние спина на траекторию (эффект Магнуса)
	# Спин создаёт боковую силу, перпендикулярную направлению движения
	var spin_effect: float = 0.0
	if not is_zero_approx(spin):
		# Коэффициент влияния спина (зависит от размера мяча и плотности воздуха)
		var spin_coefficient: float = 0.00015  # Настраиваемый коэффициент
		
		# Скорость мяча
		var ball_speed: float = v.length()
		
		# Время полёта до ракетки
		var flight_time: float = t
		
		# Эффект спина на вертикальное смещение
		# Положительный спин (по часовой стрелке) отклоняет мяч вниз
		# Отрицательный спин (против часовой стрелки) отклоняет мяч вверх
		spin_effect = spin * spin_coefficient * ball_speed * flight_time * flight_time * 0.5
		
		# Применяем настройку влияния спина
		spin_effect *= spin_influence
	
	# Финальная позиция с учётом спина
	var final_y: float = base_y + spin_effect
	
	# Обработка отскоков от стен
	var r := get_field_rect()
	var height: float = r.size.y
	var period: float = height * 2.0
	
	# Применяем периодичность для отскоков
	var top: float = r.position.y
	var local_final: float = fposmod(final_y - top, period)
	if local_final > height:
		local_final = period - local_final
	
	return Vector2(paddle_x, _clamp_y_to_field(top + local_final))

func _dodge_pos(ball_pos: Vector2) -> Vector2:
	var r := get_field_rect()
	var mid_y := r.position.y + r.size.y * 0.5
	var dir_y: float = sign(global_position.y - ball_pos.y)
	if is_zero_approx(dir_y):
		dir_y = 1.0 if ball_pos.y < mid_y else -1.0
	var target_y: float = _clamp_y_to_field(global_position.y + dir_y * 400.0)
	return Vector2(global_position.x, target_y)

func _retreat_pos() -> Vector2:
	var my_goal: Vector2 = get_goal_right() if defends_right_side else goal_left
	return my_goal.lerp(start_pos, 0.2)

func _add_error(style: Dictionary) -> void:
	var weak: float = 1.0 - skill
	var r: float = ERROR_BASE_RADIUS * weak * weak * (1.0 + weak) * float(style.error_mult)
	_target_pos += Vector2(randf_range(-r, r), randf_range(-r, r))

func _clamp_advancement() -> void:
	var r := get_field_rect()
	var limit_x: float = r.size.x * ADVANCE_LIMIT_PROPORTION
	if defends_right_side:
		_target_pos.x = max(_target_pos.x, r.position.x + limit_x)
	else:
		_target_pos.x = min(_target_pos.x, r.position.x + r.size.x - limit_x)

func _clamp_target_x() -> void:
	"""Ограничивает _target_pos.x в пределах игровой области ракетки"""
	var r: Rect2 = get_field_rect()
	var half := _resolve_half_size()
	var center_x := r.position.x + r.size.x * 0.5

	# Применяем масштаб к отступам
	var scaled_left_margin = float(LEFT_MARGIN_PX) * _scale_factor.x
	var scaled_center_bias = float(center_bias_px) * _scale_factor.x

	var min_x: float
	var max_x: float

	if defends_right_side:
		# правая половина
		if use_center_as_right_limit:
			min_x = center_x + scaled_center_bias + half.x
			max_x = r.position.x + r.size.x - scaled_left_margin - half.x
		else:
			min_x = r.position.x + scaled_left_margin + half.x
			max_x = r.position.x + r.size.x - scaled_left_margin - half.x
	else:
		# левая половина
		if use_center_as_right_limit:
			min_x = r.position.x + scaled_left_margin + half.x
			max_x = center_x - scaled_center_bias - half.x
		else:
			min_x = r.position.x + scaled_left_margin + half.x
			max_x = r.position.x + r.size.x - scaled_left_margin - half.x

	if min_x > max_x:
		max_x = min_x

	_target_pos.x = clamp(_target_pos.x, min_x, max_x)

# ---------------- Stuck Detection Functions ----------------
func _check_stuck_at_border() -> void:
	"""Проверяет, застряла ли ракетка у верхней/нижней границы"""
	var field_size = get_field_size()
	var delta = get_physics_process_delta_time()
	
	# Проверяем, находится ли ракетка близко к границам
	var near_top = global_position.y < r.position.y + _stuck_margin
	var near_bottom = global_position.y > r.position.y + r.size.y - _stuck_margin
	var near_border = near_top or near_bottom
	
	# Проверяем, далеко ли мяч
	var ball_distance = global_position.distance_to(_ball.global_position) if _ball else 0.0
	var ball_far = ball_distance > 300.0  # Мяч считается далеко, если больше 300 пикселей
	
	if near_border and ball_far:
		_stuck_timer += delta
		_emergency_reset_timer += delta
	else:
		_stuck_timer = 0.0
		_emergency_reset_timer = 0.0
	
	# Если застряли дольше порога, принудительно выходим из угла
	if _stuck_timer >= _stuck_threshold:
		_force_exit_from_corner()
	
	# Аварийный сброс позиции
	if _emergency_reset_timer >= _emergency_reset_threshold:
		reset_position()

func _force_exit_from_corner() -> void:
	"""Принудительно выводит ракетку из угла"""
	var field_size = get_field_size()
	
	# Сбрасываем задержку смены направления
	_direction_change_delay = 0.0
	
	# Устанавливаем цель в центр поля
	_target_pos = start_pos
	
	# Переводим в состояние защиты
	_state = State.DEFEND
	
	# Задаём горизонтальную скорость для выхода из угла
	var center_y = r.position.y + r.size.y * 0.5
	var direction_to_center = sign(center_y - global_position.y)
	var exit_speed = BASE_SPEED * 1.5  # Увеличенная скорость для выхода
	
	# Устанавливаем вертикальную скорость для движения к центру
	velocity.y = direction_to_center * exit_speed
	
	# Сбрасываем таймер застревания
	_stuck_timer = 0.0

# ---------------- Movement & Clamp X ----------------
func _move() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	
	# Проверяем застревание у границ
	_check_stuck_at_border()
	
	# Плавно обновляем целевую позицию
	_smooth_target_pos = _smooth_target_pos.lerp(_target_pos, _smooth_factor)
	
	# Вычисляем направление к плавной цели
	var dir: Vector2 = _smooth_target_pos - global_position
	if dir.length() < 2.0:
		velocity = Vector2.ZERO
		return
	
	dir = dir.normalized()
	
	# Задержка при смене направления для низких навыков
	if skill < 0.5:
		var current_dir = velocity.normalized() if not velocity.is_zero_approx() else Vector2.ZERO
		var direction_change = current_dir.dot(dir) < 0.5  # Значительное изменение направления
		
		if direction_change and _direction_change_delay <= 0.0:
			_direction_change_delay = lerp(0.1, 0.0, skill)  # Задержка от 0.1 до 0.0 секунд
		
		if _direction_change_delay > 0.0:
			_direction_change_delay -= get_physics_process_delta_time()
			# Во время задержки продолжаем движение в текущем направлении
			if not velocity.is_zero_approx():
				move_and_slide()
				_clamp_x()
				return
	
	# Усиливаем джиттер для низких навыков, уменьшаем для высоких
	var jitter_mag: float = pow(1.0 - skill, 1.5) * 0.5  # Усилили джиттер для низких навыков
	var speed_jitter: float = randf_range(1.0 - jitter_mag, 1.0 + jitter_mag)
	var speed: float = BASE_SPEED * float(style.speed_mul) * speed_jitter * lerp(0.4, 1.0, skill)
	
	# Настройки скорости в зависимости от состояния
	match _state:
		State.ATTACK:
			speed *= 1.2
		State.RETREAT:
			speed *= 0.8
		State.HIGH_SPEED_DEFEND:
			speed *= 1.1
		State.EDGE_GUARD:
			speed *= 0.9
	
	# Применяем дополнительное сглаживание скорости
	var current_speed = velocity.length()
	var target_speed = speed
	var speed_smooth_factor = 0.1  # Плавное изменение скорости
	var new_speed = lerp(current_speed, target_speed, speed_smooth_factor)
	
	velocity = dir * new_speed
	move_and_slide()
	
	# Обработка коллизий для предотвращения застревания в углах
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_normal().y != 0:
			_direction_change_delay = 0
	
	# Принудительное возвращение из углов
	global_position.y = _clamp_y_to_field(global_position.y)
	
	_clamp_x()

# ==========================================================
#                    HORIZONTAL CLAMP HELPERS
# ==========================================================
func _clamp_x() -> void:
	var r: Rect2 = get_field_rect()
	var half := _resolve_half_size()
	var center_x := r.position.x + r.size.x * 0.5

	# Применяем масштаб к отступам
	var scaled_left_margin = float(LEFT_MARGIN_PX) * _scale_factor.x
	var scaled_center_bias = float(center_bias_px) * _scale_factor.x

	var min_x: float
	var max_x: float

	if defends_right_side:
		# правая половина
		if use_center_as_right_limit:
			min_x = center_x + scaled_center_bias + half.x
			max_x = r.position.x + r.size.x - scaled_left_margin - half.x
		else:
			min_x = r.position.x + scaled_left_margin + half.x
			max_x = r.position.x + r.size.x - scaled_left_margin - half.x
	else:
		# левая половина
		if use_center_as_right_limit:
			min_x = r.position.x + scaled_left_margin + half.x
			max_x = center_x - scaled_center_bias - half.x
		else:
			min_x = r.position.x + scaled_left_margin + half.x
			max_x = r.position.x + r.size.x - scaled_left_margin - half.x

	if min_x > max_x:
		max_x = min_x

	global_position.x = clamp(global_position.x, min_x, max_x)

func _resolve_half_size() -> Vector2:
	# 1) Явное значение
	if half_size_override != Vector2.ZERO:
		return half_size_override
	# 2) Из коллайдера
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape:
		if cs.shape is RectangleShape2D:
			return (cs.shape as RectangleShape2D).extents
		if cs.shape is CapsuleShape2D:
			var s := cs.shape as CapsuleShape2D
			return Vector2(s.radius, s.height * 0.5)
		if cs.shape is CircleShape2D:
			var c := cs.shape as CircleShape2D
			return Vector2(c.radius, c.radius)
	# 3) Дефолт
	return Vector2(16, 16)
