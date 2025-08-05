extends RigidBody2D
class_name Ball

@export var spawn_marker_path: NodePath
const RESPAWN_DELAY := 0.5
const SERVE_SPEED   := 1200.0 # Increased serve speed
const SPEED_LIMIT   := 1600.0 # Increased top speed after ricochets
const MIN_SPEED     := 800.0  # Keep ball lively after bounces
var _spawn_point: Vector2

func _ready() -> void:
	_find_spawn()
	_teleport_to_spawn()
	_serve()

func respawn() -> void:
	_teleport_to_spawn()
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_serve()

func _serve() -> void:
	randomize()
	linear_velocity = (Vector2.RIGHT if (randi() & 1)==0 else Vector2.LEFT) * SERVE_SPEED

# ---------- helpers ----------
func _find_spawn() -> void:
	var root := get_parent()
	if spawn_marker_path == NodePath("") and root and root.has_node("SpawnPoint"):
		spawn_marker_path = self.get_path_to(root.get_node("SpawnPoint"))
	var m := get_node_or_null(spawn_marker_path) as Node2D
	_spawn_point = m.global_position if m else global_position

func _teleport_to_spawn() -> void:
	# Stop all motion
	PhysicsServer2D.body_set_state(get_rid(),
		PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(get_rid(),
		PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)

	# Hard‑teleport to spawn point
	var t := Transform2D()
	t.origin = _spawn_point
	PhysicsServer2D.body_set_state(get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM, t)

	sleeping = false

func _integrate_forces(state):
	# Boost speed slightly on every ricochet
	if state.get_contact_count() > 0:
		linear_velocity *= 1.05  # +5 % per bounce

	var v := linear_velocity.length()
	if v > SPEED_LIMIT:
		linear_velocity = linear_velocity.normalized() * SPEED_LIMIT
	elif v > 0.0 and v < MIN_SPEED:
		linear_velocity = linear_velocity.normalized() * MIN_SPEED
