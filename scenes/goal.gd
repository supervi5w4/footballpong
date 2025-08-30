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
@export var goal_cooldown: float = 1.0  # Кулдаун между голами (сек)

@onready var _score := Score
@onready var _sound: AudioStreamPlayer = get_parent().get_node_or_null("GoalSound")

var _locked: bool = false  # Защита от двойного подсчёта

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
	
	# Проверяем кулдаун: если ворота заблокированы, игнорируем
	if _locked:
		return
	
	# Блокируем ворота от повторного срабатывания
	_locked = true
	monitoring = false
	
	# Определяем автора гола
	var goal_scorer: String
	var player_goal_is_right := not _score.player_on_left
	
	if is_right_goal == player_goal_is_right:
		# мяч влетел в ворота игрока → гол ИИ
		_score.right += 1
		goal_scorer = "ИИ"
	else:
		# мяч влетел в ворота ИИ → гол игрока
		_score.left += 1
		goal_scorer = "Игрок"
	
	# Логируем событие: тайм, защитники, автор и счёт
	var player_side = "слева" if _score.player_on_left else "справа"
	var ai_side = "справа" if _score.player_on_left else "слева"
	var goal_side = "справа" if is_right_goal else "слева"
	
	print("ГОЛ! Тайм %d: %s забил в ворота %s! Игрок защищает %s, ИИ защищает %s. Счёт %d:%d" % [
		_score.current_half, goal_scorer, goal_side, player_side, ai_side, _score.left, _score.right
	])
	
	# Воспроизводим звук гола
	if _sound:
		_sound.play()
	
	# Перезапуск раунда
	var game := get_tree().get_root().get_node_or_null("Game")
	if game and game.has_method("reset_round"):
		game.reset_round()
	
	# Включаем кулдаун
	await get_tree().create_timer(goal_cooldown).timeout
	monitoring = true
	_locked = false
