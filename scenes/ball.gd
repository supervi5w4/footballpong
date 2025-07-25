# ------------------------------------------------------------
#  Ball.gd – мяч для Football Pong (с автопоиском SpawnPoint)
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends RigidBody2D
class_name Ball

@export var spawn_marker_path: NodePath   # можно указать вручную или оставить пустым

const RESPAWN_DELAY := 2.0
const SERVE_SPEED   := 900.0
const SPEED_LIMIT   := 1200.0
const MIN_SPEED     := 600.0

var _spawn_point: Vector2

func _ready() -> void:
	randomize()

	# --- Автоматический поиск SpawnPoint ---
	if spawn_marker_path == NodePath(""):
		# Ищем родителя Game
		var node := self
		while node and node.name != "Game":
			node = node.get_parent()
		if node and node.has_node("SpawnPoint"):
			spawn_marker_path = node.get_path_to(node.get_node("SpawnPoint"))
			print("Ball: SpawnPoint found at path:", spawn_marker_path)
	# --- Теперь берём позицию маркера (или fallback) ---
	if spawn_marker_path != NodePath(""):
		var marker := get_node(spawn_marker_path) as Node2D
		_spawn_point = marker.global_position
	else:
		_spawn_point = global_position  # если ничего не найдено

	_teleport_to_spawn()
	serve(_random_dir())

func _physics_process(_delta: float) -> void:
	var speed := linear_velocity.length()
	if speed < MIN_SPEED and speed > 0:
		linear_velocity = linear_velocity.normalized() * MIN_SPEED
	elif speed > SPEED_LIMIT:
		linear_velocity = linear_velocity.normalized() * SPEED_LIMIT

func reset() -> void:
	var old_layer := collision_layer
	var old_mask  := collision_mask
	collision_layer = 0
	collision_mask  = 0

	linear_velocity  = Vector2.ZERO
	angular_velocity = 0
	_teleport_to_spawn()
	sleeping = true

	await get_tree().create_timer(RESPAWN_DELAY).timeout

	collision_layer = old_layer
	collision_mask  = old_mask
	sleeping        = false
	serve(_random_dir())

func serve(dir: Vector2) -> void:
	linear_velocity = dir.normalized() * SERVE_SPEED

func _teleport_to_spawn() -> void:
	global_position = _spawn_point

func _random_dir() -> Vector2:
	if randi() % 2 == 0:
		return Vector2.LEFT
	return Vector2.RIGHT
