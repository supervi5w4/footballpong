# ------------------------------------------------------------
# utils.gd – вспомогательные функции для Football Pong
# Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Node
class_name Utils

# Отражение мяча от ракетки с учётом спина (вращения)
# Скорость ракетки раскладывается на нормальную и тангенциальную составляющие:
#   • нормальная — влияет на ускорение мяча;
#   • тангенциальная — на величину добавленного спина.
# Возвращает Dictionary:
#   vel  – новый вектор скорости мяча после столкновения
#   spin – добавленное вращение (для эффекта Магнуса)
static func reflect(
	old_vel: Vector2,
	normal: Vector2,
	paddle_vel: Vector2
) -> Dictionary:
	# 1. Разложение скорости ракетки
	var paddle_normal_speed: float = paddle_vel.dot(normal)
	var tangent: Vector2 = normal.orthogonal()
	var paddle_tangent_speed: float = paddle_vel.dot(tangent)

	# 2. Отражаем скорость от нормали и добавляем ускорение от движения ракетки
	var accel_factor: float = 1.0 + paddle_normal_speed * 0.0001
	var v_new: Vector2 = old_vel.bounce(normal) * accel_factor

	# 3. Вычисляем спин (по тангенциальной составляющей скорости ракетки)
	#    — положительное значение = topspin, отрицательное = backspin
	var spin: float = clamp(paddle_tangent_speed * 0.01, -200.0, 200.0)

	return {
		"vel": v_new,
		"spin": spin
	}
