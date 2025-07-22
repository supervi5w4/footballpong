# res://scripts/utils.gd
# Универсальная функция отражения вектора от поверхности
class_name Utils        # регистрируем класс в глобальном пространстве
static func reflect(vel: Vector2, normal: Vector2, paddle_vel: Vector2, boost := 1.0) -> Vector2:
	var reflected := vel - 2.0 * vel.dot(normal) * normal
	reflected += paddle_vel * 0.35
	return reflected.normalized() * vel.length() * boost
