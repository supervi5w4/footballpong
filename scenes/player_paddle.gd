# ------------------------------------------------------------
#  PlayerPaddle.gd – игрок-ракетка
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends CharacterBody2D
class_name PlayerPaddle

const MOVE_SPEED: float = 850.0
const Utils: Script = preload("res://scripts/utils.gd")

var start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	start_pos = global_position

func reset_position() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# Управление клавишами
	var dir: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	)
	if dir != Vector2.ZERO:
		velocity = dir.normalized() * MOVE_SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	# Отражение мяча с передачей спина (spin)
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		if col.get_collider() is RigidBody2D and col.get_collider().is_in_group("ball"):
			var info: Dictionary = Utils.reflect(
				(col.get_collider() as RigidBody2D).linear_velocity,
				col.get_normal(),
				velocity,
				1.05
			)
			var ball: RigidBody2D = col.get_collider() as RigidBody2D
			ball.linear_velocity  = info["vel"]
			ball.angular_velocity = info["spin"]
