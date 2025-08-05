# ------------------------------------------------------------
#  AiPaddle.gd – advanced bot for Football Pong
#  Godot 4.4.1 | GDScript 2.0
#  v2.1 – fixes ternary syntax for GDScript 2
# ------------------------------------------------------------
extends CharacterBody2D
class_name AiPaddle

@export var skill: float = 0.85
@export_enum("aggressive", "balanced", "defensive")
var behaviour_style: String = "balanced"

@export var ball_path:   NodePath
@export var player_path: NodePath
@export var defends_right_side: bool = true

@export var goal_left:  Vector2 = Vector2(0, 540)
@export var goal_right: Vector2 = Vector2(1920, 540)

const FIELD_SIZE:  Vector2i  = Vector2i(1920, 1080)
const HALF_FIELD_X: int      = FIELD_SIZE.x / 2
const BASE_SPEED:   float    = 850.0
const REACTION_BASE: float   = 0.12
const ATTACK_OFFSET: float   = 80.0
const ERROR_BASE_RADIUS: float = 24.0
const FIRST_HIT_DEVIATION_Y: float = 260.0   # vertical tweak for deceptive first hit
const ADVANCE_LIMIT_PROPORTION: float = 0.47 # how far across midfield AI may advance

const STYLE_DB: Dictionary = {
	"aggressive": {"speed_mul": 1.35, "risk_zone": 0.50, "error_mult": 1.2},
	"balanced":   {"speed_mul": 1.00, "risk_zone": 0.25, "error_mult": 1.0},
	"defensive":  {"speed_mul": 0.85, "risk_zone": 0.12, "error_mult": 0.8},
}

const Utils: Script = preload("res://scripts/utils.gd")

enum State { DEFEND, INTERCEPT, SECOND_BOUNCE, BLOCK_PLAYER, ATTACK, FAKE }
var _state: State = State.DEFEND

var _ball:   RigidBody2D
var _player: CharacterBody2D
var _target_pos: Vector2 = Vector2.ZERO
var _time_to_next_think: float = 0.0
var _fake_timer: float = 0.0
var start_pos: Vector2 = Vector2.ZERO

var _is_first_hit: bool = true

# ---------------- READY ----------------
func _ready() -> void:
	_ball   = get_node(ball_path)   as RigidBody2D
	_player = get_node(player_path) as CharacterBody2D
	start_pos = global_position
	_think()
	_schedule_next_think()

func reset_position() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
	_state = State.DEFEND
	_time_to_next_think = 0.0
	_fake_timer = 0.0
	_is_first_hit = true

# ---------------- MAIN ----------------
func _physics_process(delta: float) -> void:
	_time_to_next_think -= delta
	_fake_timer -= delta
	if _time_to_next_think <= 0.0:
		_think()
		_schedule_next_think()
	_move()

	# Удар по мячу с учетом spin + хитрость на первом касании
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		if col.get_collider() is RigidBody2D and col.get_collider().is_in_group("ball"):
			var info: Dictionary = Utils.reflect(
				(col.get_collider() as RigidBody2D).linear_velocity,
				col.get_normal(),
				velocity, 1.07)

			var ball: RigidBody2D = col.get_collider() as RigidBody2D

			# --- Deceptive first touch ---
			if _is_first_hit:
				var sign_dir: float = sign(ball.global_position.y - _player.global_position.y)
				info["vel"].y += sign_dir * FIRST_HIT_DEVIATION_Y
				_is_first_hit = false

			ball.linear_velocity  = info["vel"]
			ball.angular_velocity = info["spin"]

	# Сброс флага первого касания, когда мяч покидает нашу половину
	if not _is_first_hit:
		if (defends_right_side and _ball.global_position.x < HALF_FIELD_X) or \
		   (not defends_right_side and _ball.global_position.x > HALF_FIELD_X):
			_is_first_hit = true

# ---------------- THINK ----------------
func _think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	var ball_pos: Vector2 = _ball.global_position
	var player_pos: Vector2 = _player.global_position
	var ball_dir: Vector2 = _ball.linear_velocity.normalized()

	var toward_player: Vector2 = (player_pos - ball_pos).normalized()
	var toward_me:     Vector2 = (global_position - ball_pos).normalized()

	var b_to_player: bool = ball_dir.dot(toward_player) > 0.7
	var b_to_me:     bool = ball_dir.dot(toward_me)     > 0.7

	# --- FSM transitions ---
	match _state:
		State.DEFEND:
			if b_to_me:
				_state = State.INTERCEPT
			elif b_to_player and randf() < 0.5:
				_state = State.BLOCK_PLAYER
			else:
				_state = State.ATTACK
		State.INTERCEPT:
			if randf() < 0.25:
				_state = State.FAKE
			elif not b_to_me:
				_state = State.SECOND_BOUNCE
		State.SECOND_BOUNCE:
			if b_to_me:
				_state = State.INTERCEPT
			elif not b_to_player:
				_state = State.ATTACK
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

	# --- выбор позиции ---
	match _state:
		State.DEFEND:
			_target_pos = _goal_pos(ball_pos)
		State.INTERCEPT:
			_target_pos = ball_pos
		State.SECOND_BOUNCE:
			_target_pos = _predict_second_bounce()
		State.BLOCK_PLAYER:
			_target_pos = _block_pos(player_pos)
		State.FAKE:
			_target_pos = ball_pos + Vector2(randf_range(-150.0,150.0), randf_range(-100.0,100.0))
			_fake_timer = 0.25
		State.ATTACK:
			_target_pos = _attack_pos(ball_pos)

	_add_error(style)
	_clamp_advancement()

# ------------ Helpers ---------------
func _goal_pos(ball_pos: Vector2) -> Vector2:
	var my_goal: Vector2 = goal_right if defends_right_side else goal_left
	return my_goal.lerp(ball_pos, 0.25)

func _attack_pos(ball_pos: Vector2) -> Vector2:
	var enemy_goal: Vector2 = goal_left if defends_right_side else goal_right
	# небольшое смещение вверх/вниз для обмана
	var y_offset: float = ATTACK_OFFSET * sign(ball_pos.y - _player.global_position.y)
	return (ball_pos + Vector2(0, y_offset)).lerp(enemy_goal, 0.10)

func _block_pos(player_pos: Vector2) -> Vector2:
	var offset_y: float = 120.0 if player_pos.y < FIELD_SIZE.y * 0.5 else -120.0
	return Vector2(player_pos.x, clamp(player_pos.y + offset_y, 80.0, float(FIELD_SIZE.y - 80)))

func _predict_second_bounce() -> Vector2:
	var wall_x: float = float(FIELD_SIZE.x) if defends_right_side else 0.0
	var from: Vector2 = _ball.global_position
	var vel: Vector2 = _ball.linear_velocity.normalized()
	var dist: float = abs(wall_x - from.x)
	var first_hit: Vector2 = from + vel * dist                # точка 1-го отскока
	var after_bounce: Vector2 = Vector2(-vel.x, vel.y)        # отражение от вертикальной стены
	return first_hit + after_bounce * dist * 0.3              # на треть пути к 2-му отскоку

func _add_error(style: Dictionary) -> void:
	var r: float = ERROR_BASE_RADIUS * (1.0 - skill) * float(style.error_mult)
	_target_pos += Vector2(randf_range(-r, r), randf_range(-r, r))

func _clamp_advancement() -> void:
	# Не зажимаем игрока в воротах, ограничиваем продвижение
	var limit_x: float = FIELD_SIZE.x * ADVANCE_LIMIT_PROPORTION
	if defends_right_side:
		_target_pos.x = max(_target_pos.x, limit_x)
	else:
		_target_pos.x = min(_target_pos.x, FIELD_SIZE.x - limit_x)

# ------------ Movement --------------
func _move() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	var dir: Vector2 = _target_pos - global_position
	if dir.length() < 2.0:
		velocity = Vector2.ZERO
		return
	dir = dir.normalized()
	var speed: float = BASE_SPEED * float(style.speed_mul) * lerp(0.6,1.0,skill)
	if _state == State.ATTACK:
		speed *= 1.2
	velocity = dir * speed
	move_and_slide()

# ------------ Timer --------------
func _schedule_next_think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	var react: float = REACTION_BASE + (1.0 - skill) * 0.25
	react *= randf_range(0.8, 1.4) * float(style.error_mult)
	_time_to_next_think = react
