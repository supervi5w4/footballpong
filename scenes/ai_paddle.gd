extends CharacterBody2D
# ------------------------------------------------------------
#  Football Pong – интеллектуальная ракетка-соперник
#  Godot 4.4.1 Stable | GDScript 2.0  (без тернарных ? :)
# ------------------------------------------------------------

# ---------- НАСТРОЙКИ, ВИДНЫЕ В ИНСПЕКТОРЕ ----------
@export var skill: float = 0.8
@export_enum("aggressive", "balanced", "defensive")
var behaviour_style: String = "balanced"

@export var ball_path: NodePath
@export var defends_right_side: bool = true      # true — ИИ стоит справа

@export var goal_left:  Vector2 = Vector2(0, 540)
@export var goal_right: Vector2 = Vector2(1920, 540)

# ---------- КОНСТАНТЫ ----------
const FIELD_SIZE: Vector2i = Vector2i(1920, 1080)
const HALF_FIELD_X: int      = FIELD_SIZE.x / 2
const BASE_SPEED: float      = 850.0
const REACTION_BASE: float   = 0.15
const ATTACK_OFFSET: float   = 70.0
const ERROR_BASE_RADIUS: float = 32.0

# ---------- ПРОФИЛИ ПОВЕДЕНИЯ ----------
const STYLE_DB: Dictionary = {
	"aggressive": { "speed_mul": 1.25, "risk_zone": 0.35, "error_mult": 1.3 },
	"balanced":   { "speed_mul": 1.00, "risk_zone": 0.25, "error_mult": 1.0 },
	"defensive":  { "speed_mul": 0.85, "risk_zone": 0.10, "error_mult": 0.7 },
}

# ---------- ВНУТРЕННИЕ ПОЛЯ ----------
var _ball: RigidBody2D
var _time_to_next_think: float = 0.0
var _target_pos: Vector2

# ============================================================
func _ready() -> void:
	randomize()

	if ball_path == NodePath(""):
		push_error("AIPaddle.gd: ball_path не назначен!")
		return

	_ball = get_node(ball_path) as RigidBody2D
	_target_pos = global_position

	_choose_new_target()      # думаем сразу
	_schedule_next_think()

# ============================================================
func _physics_process(delta: float) -> void:
	if _ball == null:
		return

	_time_to_next_think -= delta
	if _time_to_next_think <= 0.0:
		_choose_new_target()
		_schedule_next_think()

	_move_towards_target(delta)

# ============================================================
# 3. ВЫБОР ЦЕЛЕВОЙ ТОЧКИ
# ============================================================
func _choose_new_target() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])

	# --- 3.1  Прогноз ближайшей позиции мяча ---
	var prediction_time: float = 0.25 + (1.0 - skill) * 0.3
	var predicted_pos: Vector2 = _ball.global_position + _ball.linear_velocity * prediction_time

	# --- 3.2  Определяем свои / чужие ворота ---
	var my_goal:    Vector2 = goal_right if defends_right_side else goal_left
	var enemy_goal: Vector2 = goal_left  if defends_right_side else goal_right
	var to_enemy:   Vector2 = (enemy_goal - predicted_pos).normalized()

	# --- 3.3  Мяч летит к нам? ---
	var ball_moves_to_me: bool
	if defends_right_side:
		ball_moves_to_me = _ball.linear_velocity.x > 0
	else:
		ball_moves_to_me = _ball.linear_velocity.x < 0

	# --- 3.4  Проверяем «зону вторжения» ---
	var risk_w: float = FIELD_SIZE.x * float(style["risk_zone"])
	var invade_limit_x: float
	var can_invade: bool
	if defends_right_side:
		invade_limit_x = HALF_FIELD_X + risk_w
		can_invade     = predicted_pos.x < invade_limit_x
	else:
		invade_limit_x = HALF_FIELD_X - risk_w
		can_invade     = predicted_pos.x > invade_limit_x

	# --- 3.5  Назначаем цель ---
	if ball_moves_to_me:
		_target_pos = predicted_pos                          # оборона
	else:
		_target_pos = predicted_pos - to_enemy * ATTACK_OFFSET  # атака

	# --- 3.6  Остаёмся на своей половине, если нельзя вторгаться ---
	if not can_invade:
		if defends_right_side:
			_target_pos.x = max(_target_pos.x, HALF_FIELD_X + 16.0)
		else:
			_target_pos.x = min(_target_pos.x, HALF_FIELD_X - 16.0)

	# --- 3.7  «Человеческая» погрешность ---
	var error_radius: float = ERROR_BASE_RADIUS * (1.0 - skill) * float(style["error_mult"])
	_target_pos += Vector2(
		randf_range(-error_radius, error_radius),
		randf_range(-error_radius, error_radius)
	)

# ============================================================
# 4. ДВИЖЕНИЕ К ЦЕЛИ
# ============================================================
func _move_towards_target(_delta: float) -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])

	var dir: Vector2 = _target_pos - global_position
	if dir.length() < 1.0:
		velocity = Vector2.ZERO
		return

	dir = dir.normalized()

	var speed: float = BASE_SPEED * float(style["speed_mul"])
	speed *= lerp(0.6, 1.0, skill)   # неопытный AI медленнее

	velocity = dir * speed
	move_and_slide()

# ============================================================
# 5. ИМИТАЦИЯ РЕАКЦИИ
# ============================================================
func _schedule_next_think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])

	var reaction: float = REACTION_BASE + (1.0 - skill) * 0.3
	reaction *= randf_range(0.8, 1.5) * float(style["error_mult"])
	_time_to_next_think = reaction
