extends CharacterBody2D
class_name PlayerPaddle           # не обязательно, но удобно в редакторе

# --------------------------------------------------
# ПАРАМЕТРЫ
# --------------------------------------------------
const MOVE_SPEED := 850.0
const Utils = preload("res://scripts/utils.gd")   # даёт доступ к Utils.reflect()

# --------------------------------------------------
# ОСНОВНОЙ ЦИКЛ ФИЗИКИ
# --------------------------------------------------
func _physics_process(_delta: float) -> void:
	# 1. Читаем ввод
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up"))

	velocity = dir.normalized() * MOVE_SPEED if dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	# 2. Проверяем столкновения мяча с ракеткой
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_collider() is RigidBody2D and col.get_collider().name == "Ball":
			var ball := col.get_collider() as RigidBody2D
			ball.linear_velocity = Utils.reflect(
				ball.linear_velocity,   # скорость мяча до удара
				col.get_normal(),       # нормаль столкновения
				velocity,               # скорость ракетки
				1.05)                   # лёгкий «буст» (5 %)
