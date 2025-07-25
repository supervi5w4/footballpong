# ------------------------------------------------------------
#  ai_paddle.gd – интеллектуальная ракетка-бот
#  Godot 4.4.1 | GDScript 2.0 (без тернарного оператора)
# ------------------------------------------------------------
extends CharacterBody2D
class_name AiPaddle

# ---------- 1. Экспортные параметры ----------
@export var skill: float = 0.8
@export_enum("aggressive", "balanced", "defensive")
var behaviour_style: String = "balanced"

@export var ball_path: NodePath
@export var defends_right_side: bool = true

@export var goal_left:  Vector2 = Vector2(0, 540)
@export var goal_right: Vector2 = Vector2(1920, 540)

# ---------- 2. Константы ----------
const FIELD_SIZE        := Vector2i(1920, 1080)
const HALF_FIELD_X      := FIELD_SIZE.x / 2
const BASE_SPEED        := 850.0
const REACTION_BASE     := 0.15
const ATTACK_OFFSET     := 70.0
const ERROR_BASE_RADIUS := 32.0

const STYLE_DB := {
	"aggressive": {"speed_mul": 1.25, "risk_zone": 0.45, "error_mult": 1.3},
	"balanced":   {"speed_mul": 1.00, "risk_zone": 0.25, "error_mult": 1.0},
	"defensive":  {"speed_mul": 0.85, "risk_zone": 0.10, "error_mult": 0.7},
}

# ---------- 3. Поля ----------
const Utils = preload("res://scripts/utils.gd")

var _ball: RigidBody2D
var _time_to_next_think: float = 0.0
var _target_pos: Vector2
var _is_attacking: bool = false
var start_pos: Vector2

# ---------- 4. Инициализация ----------
func _ready() -> void:
	randomize()

	if ball_path == NodePath(""):
		push_error("AiPaddle: ball_path не назначен!")
		return
	_ball = get_node(ball_path) as RigidBody2D

	start_pos   = global_position
	_target_pos = global_position

	_choose_new_target()
	_schedule_next_think()

# ---------- 4-bis. Сброс после гола ----------
func reset_position() -> void:
	global_position = start_pos
	velocity        = Vector2.ZERO
	_target_pos     = start_pos
	_time_to_next_think = 0.0        # пересчитаем на следующем кадре

# ---------- 5. Главный цикл ----------
func _physics_process(delta: float) -> void:
	if _ball == null:
		return

	_time_to_next_think -= delta
	if _time_to_next_think <= 0.0:
		_choose_new_target()
		_schedule_next_think()

	_move_towards_target()

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_collider() is RigidBody2D and col.get_collider().is_in_group("ball"):
			var ball := col.get_collider() as RigidBody2D
			ball.linear_velocity = Utils.reflect(
				ball.linear_velocity,
				col.get_normal(),
				velocity,
				1.05
			)

# ---------- 6. Логика выбора цели ----------
func _choose_new_target() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])

	# 6-A. Прогноз положения мяча
	var prediction_time: float = 0.25 + (1.0 - skill) * 0.3
	var predicted_pos:  Vector2 = _ball.global_position + _ball.linear_velocity * prediction_time

	# 6-B. Свои и чужие ворота (без ? :)
	var enemy_goal: Vector2
	if defends_right_side:
		enemy_goal = goal_left
	else:
		enemy_goal = goal_right
	var to_enemy: Vector2 = (enemy_goal - predicted_pos).normalized()

	# 6-C. Летит ли мяч к нам? (без ? :)
	var ball_moves_to_me: bool = false
	if defends_right_side:
		ball_moves_to_me = _ball.linear_velocity.x > 0
	else:
		ball_moves_to_me = _ball.linear_velocity.x < 0

	# 6-D. Риск-зона (invade_limit_x и can_invade без ? :)
	var risk_w: float = FIELD_SIZE.x * float(style.risk_zone)

	var invade_limit_x: float
	if defends_right_side:
		invade_limit_x = HALF_FIELD_X + risk_w
	else:
		invade_limit_x = HALF_FIELD_X - risk_w

	var can_invade: bool
	if defends_right_side:
		can_invade = predicted_pos.x < invade_limit_x
	else:
		can_invade = predicted_pos.x > invade_limit_x

	# 6-E. Назначаем цель
	if ball_moves_to_me:
		_target_pos   = predicted_pos
		_is_attacking = false
	else:
		_target_pos   = predicted_pos + to_enemy * ATTACK_OFFSET
		_is_attacking = true

	# 6-F. Граница центра
	if not can_invade:
		if defends_right_side:
			_target_pos.x = max(_target_pos.x, HALF_FIELD_X + 16.0)
		else:
			_target_pos.x = min(_target_pos.x, HALF_FIELD_X - 16.0)

	# 6-G. Добавляем ошибку
	var error_radius: float = ERROR_BASE_RADIUS * (1.0 - skill) * float(style.error_mult)
	_target_pos.x += randf_range(-error_radius, error_radius)
	_target_pos.y += randf_range(-error_radius, error_radius)

# ---------- 7. Движение ----------
func _move_towards_target() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])

	var dir: Vector2 = _target_pos - global_position
	if dir.length() < 1.0:
		velocity = Vector2.ZERO
		return
	dir = dir.normalized()

	var speed: float = BASE_SPEED * float(style.speed_mul)
	speed *= lerp(0.6, 1.0, skill)
	if _is_attacking:
		speed *= 1.15

	velocity = dir * speed
	move_and_slide()

# ---------- 8. Планировщик реакции ----------
func _schedule_next_think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])

	var reaction: float = REACTION_BASE + (1.0 - skill) * 0.3
	reaction *= randf_range(0.8, 1.5) * float(style.error_mult)
	_time_to_next_think = reaction
