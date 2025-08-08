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
                var shape_pos := $CollisionShape2D.global_position.x
                var half_width := get_viewport_rect().size.x * 0.5
                is_right_goal = shape_pos > half_width

func _on_body_entered(body: Node) -> void:
	# Реагируем только на мяч
	if not (body is RigidBody2D and body.is_in_group("ball")):
		return

	# Обновляем счёт (игрок всегда отображается слева)
	if _score:
		if is_right_goal == _score.player_is_home:
			_score.left += 1  # гол игрока
		else:
			_score.right += 1  # гол соперника

	# Воспроизводим звук гола
	if _sound:
		_sound.play()

	# Перезапуск раунда
	var game := get_tree().get_root().get_node_or_null("Game")
	if game and game.has_method("reset_round"):
		game.reset_round()
