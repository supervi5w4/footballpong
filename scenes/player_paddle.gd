# ------------------------------------------------------------
#  PlayerPaddle.gd – игрок-ракетка
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends CharacterBody2D
class_name PlayerPaddle

const MOVE_SPEED: float = 850.0
const Utils: Script = preload("res://scripts/utils.gd")

# На сколько далеко за центр игрок может «выглядывать»
const ADVANCE_LIMIT_PROPORTION: float = 0.45    # 0.0 – 1.0  
@export var is_left_side: bool = true            # true → левый игрок, false → правый

var start_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	start_pos = global_position


func reset_position() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	# ---------- Управление ----------
	var dir: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	)
	velocity = dir.normalized() * MOVE_SPEED if dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	# ---------- Ограничиваем игрока своей половиной ----------
	var viewport_width: float = get_viewport_rect().size.x
	var limit: float          = viewport_width * ADVANCE_LIMIT_PROPORTION

	if is_left_side:
		# Левый игрок: 0 — limit
		global_position.x = clamp(global_position.x, 0.0, limit)
	else:
		# Правый игрок: (width − limit) — width
		var right_min: float = viewport_width - limit
		global_position.x = clamp(global_position.x, right_min, viewport_width)

	# ---------- Отражаем мяч с учётом спина ----------
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		if col.get_collider() is RigidBody2D and col.get_collider().is_in_group("ball"):
			var ball: RigidBody2D = col.get_collider()
			var info: Dictionary = Utils.reflect(
				ball.linear_velocity,
				col.get_normal(),
				velocity,
				1.05            # коэффициент усиления/добавки спина
			)
			ball.linear_velocity  = info["vel"]
			ball.angular_velocity = info["spin"]
