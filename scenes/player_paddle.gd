# ------------------------------------------------------------
# PlayerPaddle.gd — игрок-ракетка (Godot 4.4.1 | GDScript 2.0)
# Ограничения по X:
#  • Слева: фиксированный отступ LEFT_MARGIN_PX
#  • Справа: центр экрана минус center_bias_px (если use_center_as_right_limit == true)
# Управление: действия ui_left/right/up/down (Input Map)
# ------------------------------------------------------------
extends CharacterBody2D
class_name PlayerPaddle

const Utils: Script = preload("res://scripts/utils.gd")

# --- Параметры движения ---
@export_range(100.0, 3000.0, 10.0) var MOVE_SPEED: float = 850.0
@export_range(0.0, 1.0, 0.01) var accel: float = 0.22        # 0 — мгновенно, 1 — очень плавно

# --- Горизонтальные ограничения ---
@export_range(0, 1000, 1) var LEFT_MARGIN_PX: int = 200
@export var use_center_as_right_limit: bool = true
@export_range(0, 600, 1) var center_bias_px: int = 50         # на сколько пикселей левее центра ограничивать

# Если знаешь точный полуразмер спрайта/коллайдера — задай здесь
@export var half_size_override: Vector2 = Vector2.ZERO

var start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	start_pos = global_position

func reset_position() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# --- Ввод: WASD/стрелки через Input Map ---
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	)
	if dir.length() > 1.0:
		dir = dir.normalized()

	# --- Плавное изменение скорости (немного "живее") ---
	var target_vel := dir * MOVE_SPEED
	velocity = velocity.lerp(target_vel, accel)

	# Движемся, затем: обработка коллизий и зажим X
	move_and_slide()
	_handle_ball_collisions()
	_clamp_x()

# ----------------- ВСПОМОГАТЕЛЬНОЕ -----------------

func _clamp_x() -> void:
	var vp: Rect2 = get_viewport_rect()
	var half: Vector2 = _resolve_half_size()

	var min_x: float = vp.position.x + float(LEFT_MARGIN_PX) + half.x

	var right_limit: float = vp.position.x + vp.size.x
	if use_center_as_right_limit:
		right_limit = vp.position.x + vp.size.x * 0.5 - float(center_bias_px)

	var max_x: float = right_limit - half.x

	# Подстраховка: если окно узкое и границы пересеклись
	if min_x > max_x:
		max_x = min_x

	global_position.x = clamp(global_position.x, min_x, max_x)

func _handle_ball_collisions() -> void:
	# В CharacterBody2D коллизии доступны после move_and_slide()
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var rb := col.get_collider() as RigidBody2D
		if rb and rb.is_in_group("ball"):
			var info: Dictionary = Utils.reflect(rb.linear_velocity, col.get_normal(), velocity, 1.07)
			rb.linear_velocity  = info["vel"]
			rb.angular_velocity = info["spin"]

func _resolve_half_size() -> Vector2:
	# 1) Явное значение
	if half_size_override != Vector2.ZERO:
		return half_size_override

	# 2) Из коллайдера
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape:
		if cs.shape is RectangleShape2D:
			return (cs.shape as RectangleShape2D).extents # extents = полуразмеры
		if cs.shape is CapsuleShape2D:
			var s := cs.shape as CapsuleShape2D
			return Vector2(s.radius, s.height * 0.5)
		if cs.shape is CircleShape2D:
			var c := cs.shape as CircleShape2D
			return Vector2(c.radius, c.radius)

	# 3) Дефолт
	return Vector2(16, 16)
