# ------------------------------------------------------------
# AiPaddle.gd — Advanced AI for Football Pong
# Godot 4.4.1 | GDScript 2.0 | v2.6 (HIGH_SPEED_DEFEND, EDGE_GUARD)
# ------------------------------------------------------------
extends CharacterBody2D
class_name AiPaddle

# ---------------- Tunables & Constants ----------------
@export var skill: float = 0.85
@export_enum("aggressive", "balanced", "defensive")
var behaviour_style: String = "balanced"

@export var ball_path: NodePath
@export var player_path: NodePath
@export var defends_right_side: bool = true

@export var max_bounces: int = 3
@export var wall_bounce_damp: float = 0.9
@export var paddle_bounce_damp: float = 0.8

@export var goal_left: Vector2 = Vector2(0, 540)
@export var goal_right: Vector2 = Vector2(1920, 540)

const FIELD_SIZE: Vector2i = Vector2i(1920, 1080)
const HALF_FIELD_X: int = FIELD_SIZE.x / 2
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
	_handle_ball_collisions()
	_check_first_hit_reset()

# ------------ Collision & First‑hit helpers ------------
func _handle_ball_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		if col.get_collider() is RigidBody2D and col.get_collider().is_in_group("ball"):
			var info: Dictionary = Utils.reflect(
				(col.get_collider() as RigidBody2D).linear_velocity,
				col.get_normal(),
				velocity, 1.07)
			var ball: RigidBody2D = col.get_collider() as RigidBody2D
			if _is_first_hit:
				var sign_dir: float = sign(ball.global_position.y - _player.global_position.y)
				info["vel"].y += sign_dir * FIRST_HIT_DEVIATION_Y
				_is_first_hit = false
			ball.linear_velocity  = info["vel"]
			ball.angular_velocity = info["spin"]

func _check_first_hit_reset() -> void:
	if not _is_first_hit:
		var left_side: bool = _ball.global_position.x < HALF_FIELD_X
		if (defends_right_side and left_side) or (not defends_right_side and not left_side):
			_is_first_hit = true

# ---------------- THINK ----------------
func _think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	var ball_pos: Vector2 = _ball.global_position
	var player_pos: Vector2 = _player.global_position
	var ball_dir: Vector2 = _ball.linear_velocity.normalized()
	var ball_behind: bool = _is_ball_behind()
	var heading_to_goal: bool = (defends_right_side and _ball.linear_velocity.x > 0.0) or (not defends_right_side and _ball.linear_velocity.x < 0.0)

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
		var ball_speed: float = _ball.linear_velocity.length()
		var fast_ball: bool = ball_speed > FAST_BALL_SPEED
		var edge_near: bool = ball_pos.y < EDGE_MARGIN or ball_pos.y > float(FIELD_SIZE.y) - EDGE_MARGIN
		var strong_hit: bool = b_to_me and (ball_speed > STRONG_HIT_SPEED or abs(ball_dir.y) > STRONG_HIT_ANGLE)

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
			_target_pos = _predict_multi_bounce(ball_pos, _ball.linear_velocity, max_bounces)
		else:
			match _state:
				State.DEFEND:
					_state = State.INTERCEPT if b_to_me else State.BLOCK_PLAYER if b_to_player and randf() < 0.5 else State.ATTACK
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
					_target_pos = _predict_intercept()
				State.BLOCK_PLAYER:
					_target_pos = _block_pos(player_pos)
				State.FAKE:
					_target_pos = ball_pos + Vector2(randf_range(-150.0,150.0), randf_range(-100.0,100.0))
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

# ------------ Helper Calculations ---------------
func _goal_pos(ball_pos: Vector2) -> Vector2:
	var my_goal: Vector2 = goal_right if defends_right_side else goal_left
	return my_goal.lerp(ball_pos, 0.25)

func _attack_pos(ball_pos: Vector2) -> Vector2:
	var enemy_goal: Vector2 = goal_left if defends_right_side else goal_right
	var y_offset: float = ATTACK_OFFSET * sign(ball_pos.y - _player.global_position.y)
	return (ball_pos + Vector2(0, y_offset)).lerp(enemy_goal, 0.10)

func _block_pos(player_pos: Vector2) -> Vector2:
	var offset_y: float = 120.0 if player_pos.y < FIELD_SIZE.y * 0.5 else -120.0
	return Vector2(player_pos.x, clamp(player_pos.y + offset_y, 80.0, float(FIELD_SIZE.y - 80)))

func _high_speed_pos(ball_pos: Vector2) -> Vector2:
	var intercept: Vector2 = _predict_intercept()
	return intercept.lerp(_goal_pos(ball_pos), 0.5)

func _edge_guard_pos(ball_pos: Vector2) -> Vector2:
	var target_y: float = 80.0 if ball_pos.y < FIELD_SIZE.y * 0.5 else float(FIELD_SIZE.y - 80.0)
	return Vector2(global_position.x, target_y)

func _predict_second_bounce() -> Vector2:
	var wall_x: float = float(FIELD_SIZE.x) if defends_right_side else 0.0
	var from: Vector2 = _ball.global_position
	var vel: Vector2 = _ball.linear_velocity.normalized()
	var dist: float = abs(wall_x - from.x)
	var first_hit: Vector2 = from + vel * dist
	var after_bounce: Vector2 = Vector2(-vel.x, vel.y)
	return first_hit + after_bounce * dist * 0.3

func _predict_multi_bounce(ball_pos: Vector2, velocity: Vector2, max_bounces: int) -> Vector2:
	var pos: Vector2 = ball_pos
	var vel: Vector2 = velocity
	var top: float = 0.0
	var bottom: float = float(FIELD_SIZE.y)
	var target_x: float = global_position.x
	var player_x: float = _player.global_position.x
	var b: int = 0
	while b < max_bounces:
		var toward_me: bool = (defends_right_side and vel.x > 0.0) or (not defends_right_side and vel.x < 0.0)
		if toward_me:
			var t_to_me: float = (target_x - pos.x) / vel.x
			if t_to_me >= 0.0:
				pos += vel * t_to_me
				return Vector2(target_x, clamp(pos.y, 80.0, bottom - 80.0))
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
			t_player = (player_x - pos.x) / vel.x
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
		return Vector2(target_x, clamp(pos.y, 80.0, bottom - 80.0))
	var t_final: float = (target_x - pos.x) / vel.x
	pos += vel * t_final
	return Vector2(target_x, clamp(pos.y, 80.0, bottom - 80.0))

# ---------- Prediction / Dodge helpers ----------
func _is_on_my_side(pos: Vector2) -> bool:
	return (defends_right_side and pos.x > HALF_FIELD_X) or (not defends_right_side and pos.x < HALF_FIELD_X)

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
	var height: float = FIELD_SIZE.y
	var period: float = height * 2.0
	y = fposmod(y, period)
	if y > height:
		y = period - y
	return Vector2(paddle_x, clamp(y, 80.0, height - 80.0))

func _dodge_pos(ball_pos: Vector2) -> Vector2:
	var dir_y: float = sign(global_position.y - ball_pos.y)
	if is_zero_approx(dir_y):
		dir_y = 1.0 if ball_pos.y < FIELD_SIZE.y * 0.5 else -1.0
	var target_y: float = clamp(global_position.y + dir_y * 400.0, 80.0, float(FIELD_SIZE.y - 80.0))
	return Vector2(global_position.x, target_y)

func _retreat_pos() -> Vector2:
	var my_goal: Vector2 = goal_right if defends_right_side else goal_left
	return my_goal.lerp(start_pos, 0.2)

func _add_error(style: Dictionary) -> void:
	var r: float = ERROR_BASE_RADIUS * (1.0 - skill) * float(style.error_mult)
	_target_pos += Vector2(randf_range(-r, r), randf_range(-r, r))

func _clamp_advancement() -> void:
	var limit_x: float = FIELD_SIZE.x * ADVANCE_LIMIT_PROPORTION
	if defends_right_side:
		_target_pos.x = max(_target_pos.x, limit_x)
	else:
		_target_pos.x = min(_target_pos.x, FIELD_SIZE.x - limit_x)

func _move() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	var dir: Vector2 = _target_pos - global_position
	if dir.length() < 2.0:
		velocity = Vector2.ZERO
		return
	dir = dir.normalized()
	var speed: float = BASE_SPEED * float(style.speed_mul) * lerp(0.6, 1.0, skill)
	match _state:
		State.ATTACK:
			speed *= 1.2
		State.RETREAT:
			speed *= 0.8
		State.HIGH_SPEED_DEFEND:
			speed *= 1.1
		State.EDGE_GUARD:
			speed *= 0.9
	velocity = dir * speed
	move_and_slide()

func _schedule_next_think() -> void:
	var style: Dictionary = STYLE_DB.get(behaviour_style, STYLE_DB["balanced"])
	var react: float = REACTION_BASE + (1.0 - skill) * 0.25
	react *= randf_range(0.8, 1.4) * float(style.error_mult)
	_time_to_next_think = react
