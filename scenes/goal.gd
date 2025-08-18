# ------------------------------------------------------------
# goal.gd — фиксируем гол, обновляем счёт, звук и рестарт раунда
# Требует:
#   - объект в группе "ball"
#   - синглтон Score (Autoload)
#   - узел Game с методом reset_round()
#   - AudioStreamPlayer "GoalSound" в родителе (необязательно)
# ------------------------------------------------------------

extends Area2D

@export var is_right_goal: bool = false  # true → ворота справа (бот)

@onready var _score := Score
@onready var _sound: AudioStreamPlayer = get_parent().get_node_or_null("GoalSound")

func _ready() -> void:
	# Определяем сторону ворот автоматически по позиции коллизии
	if not Engine.is_editor_hint():
		var shape_pos: float = ($CollisionShape2D as CollisionShape2D).global_position.x
		var half_width := get_viewport_rect().size.x * 0.5
		is_right_goal = shape_pos > half_width

func _on_body_entered(body: Node) -> void:
	# Реагируем только на мяч
	if not (body is RigidBody2D and body.is_in_group("ball")):
		return

	# Определяем: где ворота игрока?
	var player_goal_is_right := not _score.player_on_left

	if is_right_goal == player_goal_is_right:
		# мяч влетел в ворота игрока → очко сопернику
		_score.right += 1
	else:
		# мяч влетел в ворота бота → очко игроку
		_score.left += 1

	# Воспроизводим звук гола
	if _sound:
		_sound.play()

	# Показываем рекламу при забивании
	YandexSDK.show_interstitial_on_goal()

	# Перезапуск раунда
	var game := get_tree().get_root().get_node_or_null("Game")
	if game and game.has_method("reset_round"):
		game.reset_round()
