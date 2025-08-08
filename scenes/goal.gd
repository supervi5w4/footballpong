# ------------------------------------------------------------
#  goal.gd – фиксируем гол, обновляем счёт, звук и рестарт раунда
# ------------------------------------------------------------
extends Area2D

@export var is_right_goal: bool = false   # true → эти ворота справа (бот)

@onready var _score := get_node("/root/Score")
@onready var _sound := get_parent().get_node_or_null("GoalSound") as AudioStreamPlayer

func _ready() -> void:
	# Если не задано явно — определяем сторону по позиции относительно центра экрана
	if not Engine.is_editor_hint():
		var view_rect: Rect2 = get_viewport_rect()
		var half_width: float = view_rect.size.x * 0.5
		is_right_goal = global_position.x > half_width

	# Подключаем сигнал
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Только для мяча
	if not (body is RigidBody2D and body.is_in_group("ball")):
		return

	# Обновляем счёт
	if is_right_goal:
		_score.left += 1
	else:
		_score.right += 1

	if _sound:
		_sound.play()

	# Рестарт раунда
	var game := get_tree().get_root().get_node_or_null("Game")
	if game and game.has_method("reset_round"):
		game.reset_round()
