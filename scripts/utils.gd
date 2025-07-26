# ------------------------------------------------------------
#  utils.gd – вспомогательные функции для Football Pong
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Node
class_name Utils

# Отражение мяча от ракетки с учётом спина (вращения)
# Возвращает Dictionary:
#   vel  – новый вектор скорости мяча после столкновения
#   spin – добавленное вращение (для эффекта Магнуса)
static func reflect(
	old_vel: Vector2,
	normal: Vector2,
	paddle_vel: Vector2,
	boost: float = 1.0
) -> Dictionary:
	# 1. Отражаем скорость от нормали (стандартный bounce)
	var v_new: Vector2 = old_vel.bounce(normal) * boost

	# 2. Вычисляем спин (по вертикальной составляющей скорости ракетки)
	#    — вниз = backspin, вверх = topspin
	var spin: float = clamp(paddle_vel.y * 0.01, -200.0, 200.0)

	return { "vel": v_new, "spin": spin }

# (Можно добавить и другие утилиты по мере роста проекта)
