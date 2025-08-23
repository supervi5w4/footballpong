extends RigidBody2D
class_name Ball

@export var spawn_marker_path: NodePath
@export var serve_angle_deg: float = 15.0   # разброс по вертикали при подаче (±градусы)
@export_range(1.05, 1.25, 0.01) var speed_boost_per_hit: float = 1.15  # Ускорение при каждом ударе (5-25%)
@export_range(1200.0, 2000.0, 50.0) var speed_limit: float = 1600.0  # Максимальная скорость мяча

const RESPAWN_DELAY := 0.5
const SERVE_SPEED   := 1200.0  # Increased serve speed
const MIN_SPEED     := 800.0   # Keep ball lively after bounces

var _spawn_point: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _current_speed_multiplier: float = 1.0  # Текущий множитель скорости

func _ready() -> void:
	_rng.randomize()
	_find_spawn()
	_teleport_to_spawn()
	_serve()

func respawn() -> void:
	_teleport_to_spawn()
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_serve()

func _serve() -> void:
	# Случайно вправо/влево, плюс небольшой вертикальный угол
	var dir_x: float = 1.0 if _rng.randi() & 1 == 0 else -1.0
	var ang: float = deg_to_rad(_rng.randf_range(-serve_angle_deg, serve_angle_deg))
	var dir: Vector2 = Vector2(dir_x, 0.0).rotated(ang).normalized()
	linear_velocity = dir * SERVE_SPEED
	angular_velocity = 0.0
	sleeping = false
	# Сбрасываем множитель скорости при подаче
	_current_speed_multiplier = 1.0

# Функция для увеличения скорости мяча при ударе ракеткой
func boost_speed() -> void:
	var current_speed = linear_velocity.length()
	
	# Увеличиваем скорость на 15-20% при каждом ударе
	var speed_boost = speed_boost_per_hit
	
	# Если скорость уже близка к лимиту, уменьшаем ускорение
	if current_speed > speed_limit * 0.8:
		speed_boost = lerp(1.0, speed_boost_per_hit, 0.5)  # Уменьшаем ускорение наполовину
	
	var new_speed = current_speed * speed_boost
	
	# Применяем ограничение максимальной скорости
	if new_speed > speed_limit:
		new_speed = speed_limit
	
	# Применяем новую скорость, сохраняя направление
	if current_speed > 0:
		linear_velocity = linear_velocity.normalized() * new_speed

# ---------- helpers ----------
func _find_spawn() -> void:
	var root := get_parent()
	if (spawn_marker_path.is_empty()) and root and root.has_node("SpawnPoint"):
		spawn_marker_path = self.get_path_to(root.get_node("SpawnPoint"))
	var m := get_node_or_null(spawn_marker_path) as Node2D
	_spawn_point = (m.global_position if m else global_position)
	
	# Если родитель - это Game, получаем позицию спавна от него
	if root and root.has_method("get_spawn_position"):
		_spawn_point = root.get_spawn_position()

func _teleport_to_spawn() -> void:
	# Полная остановка
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)

	# Жёсткий телепорт
	var t := Transform2D()
	t.origin = _spawn_point
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, t)

	sleeping = false

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var v := linear_velocity.length()
	if v > speed_limit:
		linear_velocity = linear_velocity.normalized() * speed_limit
	elif v > 0.0 and v < MIN_SPEED:
		linear_velocity = linear_velocity.normalized() * MIN_SPEED
