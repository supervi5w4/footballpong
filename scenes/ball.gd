extends RigidBody2D
# --------------------------------------------------
# Скрипт мяча: отвечает за старт, скорость и перезапуск
# --------------------------------------------------

const SERVE_SPEED   := 700.0       # скорость начального ввода мяча
const BASE_SPEED    := 750.0       # минимальная «здоровая» скорость
const SPEED_LIMIT   := 900.0       # верхний предел, чтобы мяч не «ускорялся» бесконечно
const RESPAWN_DELAY := 2.0         # пауза после гола (сек)

var start_position : Vector2       # здесь запоминаем точку центра поля

func _ready() -> void:
	start_position = global_position
	reset()                         # первый ввод мяча при старте сцены

func _physics_process(_delta: float) -> void:
	# Нормируем скорость в каждом кадре
	var speed := linear_velocity.length()
	if speed < BASE_SPEED:
		linear_velocity = linear_velocity.normalized() * BASE_SPEED
	elif speed > SPEED_LIMIT:
		linear_velocity = linear_velocity.normalized() * SPEED_LIMIT

func serve(direction: int) -> void:
	# direction: 1 — вправо, -1 — влево
	linear_velocity = Vector2(SERVE_SPEED * direction,
							  randf_range(-200.0, 200.0))   # лёгкий разброс по Y

func reset() -> void:
	global_position = start_position
	linear_velocity = Vector2.ZERO
	# ждём 2 секунды и подаём мяч в случайную сторону
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	var dir := 1 if randf() > 0.5 else -1
	serve(dir)
