extends Area2D
@export var is_right_goal: bool = false         # true → правые ворота (бот)

@onready var _score := get_node("/root/Score")
@onready var _ui    := get_tree().root.get_node("Game/UI")
@onready var _sound := get_tree().root.get_node("Game/GoalSound") as AudioStreamPlayer
@onready var _game  := get_tree().root.get_node("Game")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not (body is RigidBody2D and body.is_in_group("ball")):
		return

	# ---- 1. Обновляем счёт ----
	if is_right_goal:
		_score.left += 1
	else:
		_score.right += 1

	_update_ui()
	_play_sound()

	# ---- 2. Проверяем условие рекламы ----
	_try_show_ad_once()

	# ---- 3. Рестарт раунда ----
	_game.reset_round()

# ---------- ВСПОМОГАТЕЛЬНЫЕ ----------
func _update_ui() -> void:
	(_ui.get_node("ScoreLeft")  as Label).text = str(_score.left)
	(_ui.get_node("ScoreRight") as Label).text = str(_score.right)

func _play_sound() -> void:
	if _sound: _sound.play()

func _try_show_ad_once() -> void:
	if _score.ad_shown:
		return                      # уже показывали

	if _score.left == 4 or _score.right == 4:
		if Engine.has_singleton("YandexSDK"):      # SDK доступен только в Web-сборке
			YandexSDK.show_ad()                    # показывает интерстициальную рекламу
		_score.ad_shown = true                     # больше не показывать
