# ------------------------------------------------------------
#  goal.gd – фиксируем гол, обновляем счёт, звук и рестарт раунда
#  Требует два синглтона:
#    1) Score  – счётчик (score_manager.gd, добавлен в Autoload как “Score”)
#    2) Game   – корневая сцена Game.tscn, содержит метод reset_round()
# ------------------------------------------------------------
extends Area2D
class_name Goal

@export var is_right_goal: bool = false   # true → эти ворота справа (бот)

# ---------- SINGLETONS & COMMON NODES ----------
@onready var _score := Score                                   # глобальный счёт
@onready var _game  := get_tree().get_root().get_node("Game")  # корень сцены с reset_round()

# UI-слой с лейблами счёта и звуковой эффект гола
@onready var _ui    := _game.get_node("UI")
@onready var _sound := _game.get_node("GoalSound") as AudioStreamPlayer

# ---------------- READY ----------------
#func _ready() -> void:
	# Страхуемся от повторного подключения, если кто-то случайно
	# подключит сигнал через инспектор
#	if not body_entered.is_connected(_on_body_entered):
#		body_entered.connect(_on_body_entered)

# ---------------- SIGNAL ----------------
func _on_body_entered(body: Node) -> void:
	# 1. реагируем только на мяч
	if not (body is RigidBody2D and body.is_in_group("ball")):
		return

	# 2. обновляем счёт
	if is_right_goal:
		_score.left  += 1        # гол забил игрок (мяч в правых воротах)
	else:
		_score.right += 1        # гол забил бот   (мяч в левых воротах)

	_update_ui()
	_play_sound()

	# 3. рестарт всего раунда: мяч + обе ракетки → центр/старт
	_game.reset_round()

# ---------------- HELPERS ----------------
func _update_ui() -> void:
	(_ui.get_node("ScoreLeft")  as Label).text = str(_score.left)
	(_ui.get_node("ScoreRight") as Label).text = str(_score.right)

func _play_sound() -> void:
	if _sound:
		_sound.play()
