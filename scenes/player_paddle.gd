# ------------------------------------------------------------
#  PlayerPaddle.gd – ракетка-футболист игрока
#  Godot 4.4.1  |  GDScript 2.0
# ------------------------------------------------------------
extends CharacterBody2D
class_name PlayerPaddle

# ---------------- ПАРАМЕТРЫ ----------------
@export var move_speed: float = 850.0               # скорость перемещения
const Utils = preload("res://scripts/utils.gd")     # отражение мяча

# ---------------- ВНУТРЕННЕЕ ----------------
var start_pos: Vector2                              # запомним исходную точку

# ---------------- READY ----------------
func _ready() -> void:
	# Сохраняем позицию, где игрок стоит при загрузке сцены
	start_pos = global_position

# Метод для полного «ресета» после гола (вызывает Game.reset_round)
func reset_position() -> void:
	global_position = start_pos     # вернуть на исходное место
	velocity = Vector2.ZERO         # остановить движение

# ---------------- ГЛАВНЫЙ ФИЗИЧЕСКИЙ ЦИКЛ ----------------
func _physics_process(_delta: float) -> void:
	# 1. Читаем ввод (стрелки или переопределённые действия ui_*)
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	)

	# 2. Вычисляем скорость: нормализуем, чтоб диагональ не была быстрее
	velocity = dir.normalized() * move_speed if dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	# 3. Проверяем столкновения и отражаем мяч
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_collider() is RigidBody2D and col.get_collider().is_in_group("ball"):
			var ball := col.get_collider() as RigidBody2D
			ball.linear_velocity = Utils.reflect(
				ball.linear_velocity,   # скорость до удара
				col.get_normal(),       # нормаль контакта
				velocity,               # скорость ракетки
				1.05                    # +5 % ускорения
			)
