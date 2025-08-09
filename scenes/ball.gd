extends RigidBody2D
class_name Ball

@export var spawn_marker_path: NodePath
@export var serve_angle_deg: float = 15.0   # разброс по вертикали при подаче (±градусы)

const RESPAWN_DELAY := 0.5
const SERVE_SPEED   := 1200.0  # Increased serve speed
const SPEED_LIMIT   := 1600.0  # Increased top speed after ricochets
const MIN_SPEED     := 800.0   # Keep ball lively after bounces

var _spawn_point: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()

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

# ---------- helpers ----------
func _find_spawn() -> void:
	var root := get_parent()
	if (spawn_marker_path.is_empty()) and root and root.has_node("SpawnPoint"):
		spawn_marker_path = self.get_path_to(root.get_node("SpawnPoint"))
	var m := get_node_or_null(spawn_marker_path) as Node2D
	_spawn_point = (m.global_position if m else global_position)

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
	if v > SPEED_LIMIT:
		linear_velocity = linear_velocity.normalized() * SPEED_LIMIT
	elif v > 0.0 and v < MIN_SPEED:
		linear_velocity = linear_velocity.normalized() * MIN_SPEED
