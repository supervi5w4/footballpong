# ------------------------------------------------------------
# PlayerPaddle.gd — игрок-ракетка (Godot 4.4.1 | GDScript 2.0)
# Ограничения по X:
#  • Левая сторона: фиксированный отступ LEFT_MARGIN_PX
#  • Правая сторона: центр экрана минус center_bias_px (если use_center_as_right_limit == true)
#  • Кастомные настройки для правой стороны: use_custom_right_side_limits
# Управление: действия ui_left/right/up/down (Input Map)
# ------------------------------------------------------------
extends CharacterBody2D
class_name PlayerPaddle

const Utils: Script = preload("res://scripts/utils.gd")

# --- Параметры движения ---
@export_range(100.0, 3000.0, 10.0) var MOVE_SPEED: float = 850.0
@export_range(0.0, 1.0, 0.01) var accel: float = 0.22  # 0 — мгновенно, 1 — очень плавно

# --- Горизонтальные ограничения ---
@export_range(0, 1000, 1) var LEFT_MARGIN_PX: int = 200
@export var use_center_as_right_limit: bool = true
@export_range(0, 600, 1) var center_bias_px: int = 50  # на сколько пикселей левее центра ограничивать (увеличено для защиты ворот)
@export var defends_right_side: bool = false  # true → игрок защищает правую сторону поля

# --- Дополнительные настройки для правой стороны поля ---
@export var use_custom_right_side_limits: bool = false  # использовать кастомные ограничения для правой стороны
@export_range(0, 1000, 1) var RIGHT_SIDE_LEFT_MARGIN: int = 0  # левый отступ для игрока на правой стороне
@export_range(0, 1000, 1) var RIGHT_SIDE_RIGHT_MARGIN: int = 100  # правый отступ для игрока на правой стороне
@export var right_side_can_reach_center: bool = true  # может ли игрок правой стороны доходить до центра
@export_range(0, 600, 1) var right_side_center_bias_px: int = 50  # отступ от центра для игрока правой стороны

# Если знаешь точный полуразмер спрайта/коллайдера — задай здесь
@export var half_size_override: Vector2 = Vector2.ZERO

var start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# подстраховка на случай кривых значений в инспекторе
	accel = clamp(accel, 0.0, 1.0)
	start_pos = global_position
	
	# Отладочная информация при запуске
	if OS.is_debug_build():
		print("PlayerPaddle ready - initial settings:")
		print_current_settings()

func reset_position() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO

func set_defends_right_side(value: bool) -> void:
	"""Устанавливает флаг защиты правой стороны поля"""
	defends_right_side = value

func enable_custom_right_side_limits() -> void:
	"""Включает кастомные ограничения для правой стороны поля"""
	use_custom_right_side_limits = true

func disable_custom_right_side_limits() -> void:
	"""Отключает кастомные ограничения для правой стороны поля"""
	use_custom_right_side_limits = false

func set_right_side_center_access(can_reach: bool) -> void:
	"""Устанавливает, может ли игрок правой стороны доходить до центра поля"""
	right_side_can_reach_center = can_reach

func set_right_side_margins(left_margin: int, right_margin: int) -> void:
	"""Устанавливает отступы для игрока правой стороны поля"""
	RIGHT_SIDE_LEFT_MARGIN = left_margin
	RIGHT_SIDE_RIGHT_MARGIN = right_margin

func setup_right_side_player() -> void:
	"""Быстрая настройка игрока для правой стороны поля"""
	defends_right_side = true
	use_custom_right_side_limits = true
	right_side_can_reach_center = true
	RIGHT_SIDE_LEFT_MARGIN = 50
	RIGHT_SIDE_RIGHT_MARGIN = 200
	right_side_center_bias_px = 50
	print("Right side player setup complete!")

func print_current_settings() -> void:
	"""Выводит текущие настройки ограничений"""
	print("=== Current Settings ===")
	print("defends_right_side: ", defends_right_side)
	print("use_custom_right_side_limits: ", use_custom_right_side_limits)
	print("right_side_can_reach_center: ", right_side_can_reach_center)
	print("RIGHT_SIDE_LEFT_MARGIN: ", RIGHT_SIDE_LEFT_MARGIN)
	print("RIGHT_SIDE_RIGHT_MARGIN: ", RIGHT_SIDE_RIGHT_MARGIN)
	print("right_side_center_bias_px: ", right_side_center_bias_px)
	print("========================")

func test_right_side_limits() -> void:
	"""Тестирует настройки правой стороны - вызовите эту функцию из инспектора"""
	print("=== Testing Right Side Limits ===")
	setup_right_side_player()
	print_current_settings()
	
	# Принудительно вызываем clamp для проверки
	_clamp_x()
	print("Test complete! Check console for debug info.")

func _physics_process(_delta: float) -> void:
	# --- Ввод: WASD/стрелки через Input Map ---
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()

	# --- Плавное изменение скорости (немного "живее") ---
	var target_vel := dir * MOVE_SPEED
	velocity = velocity.lerp(target_vel, accel)

	# Движемся, затем: обработка коллизий и зажим X
	move_and_slide()
	_handle_ball_collisions()
	_clamp_x()
	
	# Отладочная информация о позиции (только если движемся)
	if OS.is_debug_build() and velocity.length() > 0:
		print("Position after clamp: ", global_position.x)

# ----------------- ВСПОМОГАТЕЛЬНОЕ -----------------

func _clamp_x() -> void:
	var vp: Rect2 = get_viewport_rect()
	var half: Vector2 = _resolve_half_size()
	var center_x: float = vp.position.x + vp.size.x * 0.5

	var min_x: float
	var max_x: float

	if defends_right_side:
		# правая половина поля
		if use_custom_right_side_limits:
			# Используем кастомные настройки для правой стороны
			if right_side_can_reach_center:
				min_x = center_x + float(right_side_center_bias_px) + half.x
			else:
				# Если не может доходить до центра, используем фиксированный отступ от левого края
				min_x = vp.position.x + float(RIGHT_SIDE_LEFT_MARGIN) + half.x
			max_x = vp.position.x + vp.size.x - float(RIGHT_SIDE_RIGHT_MARGIN) - half.x
		elif use_center_as_right_limit:
			min_x = center_x + float(center_bias_px) + half.x
			max_x = vp.position.x + vp.size.x - float(LEFT_MARGIN_PX) - half.x
		else:
			min_x = vp.position.x + float(LEFT_MARGIN_PX) + half.x
			max_x = vp.position.x + vp.size.x - float(LEFT_MARGIN_PX) - half.x
	else:
		# левая половина поля
		if use_center_as_right_limit:
			min_x = vp.position.x + float(LEFT_MARGIN_PX) + half.x
			max_x = center_x - float(center_bias_px) - half.x
		else:
			min_x = vp.position.x + float(LEFT_MARGIN_PX) + half.x
			max_x = vp.position.x + vp.size.x - float(LEFT_MARGIN_PX) - half.x

	# Подстраховка: если окно узкое и границы пересеклись
	if min_x > max_x:
		max_x = min_x

	# Отладочная информация
	if OS.is_debug_build():
		print("Clamp Debug - defends_right_side: ", defends_right_side)
		print("Clamp Debug - use_custom_right_side_limits: ", use_custom_right_side_limits)
		print("Clamp Debug - right_side_can_reach_center: ", right_side_can_reach_center)
		print("Clamp Debug - min_x: ", min_x, " max_x: ", max_x)
		print("Clamp Debug - current_x: ", global_position.x)
		print("Clamp Debug - viewport_size: ", vp.size)
		print("Clamp Debug - center_x: ", center_x)

	global_position.x = clamp(global_position.x, min_x, max_x)

func _handle_ball_collisions() -> void:
	# В CharacterBody2D коллизии доступны после move_and_slide()
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var rb := col.get_collider() as RigidBody2D
		if rb and rb.is_in_group("ball"):
			var normal: Vector2 = col.get_normal()
			var info: Dictionary = Utils.reflect(rb.linear_velocity, normal, velocity)
			rb.linear_velocity  = info["vel"]
			rb.angular_velocity = info["spin"]
			# Увеличиваем скорость мяча при ударе
			if rb is Ball:
				rb.boost_speed()

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

# ------------------------------------------------------------
# ПРИМЕР ИСПОЛЬЗОВАНИЯ НОВЫХ НАСТРОЕК:
# 
# # Настройка игрока для правой стороны поля
# var player = $PlayerPaddle
# player.set_defends_right_side(true)
# player.enable_custom_right_side_limits()
# player.set_right_side_center_access(true)  # может доходить до центра
# player.set_right_side_margins(150, 100)    # отступы от краев
# 
# # Или через инспектор:
# # - defends_right_side = true
# # - use_custom_right_side_limits = true
# # - right_side_can_reach_center = true
# # - RIGHT_SIDE_LEFT_MARGIN = 150
# # - RIGHT_SIDE_RIGHT_MARGIN = 100
# ------------------------------------------------------------
