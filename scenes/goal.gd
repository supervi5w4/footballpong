# ------------------------------------------------------------
#  goal.gd – фиксируем гол, обновляем счёт, звук и рестарт
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Area2D
class_name GoalArea      # чтобы удобно назначать в инспекторе

@export var is_right_goal : bool = false   # true → ворота справа (бот)

# --- Lazy-ссылки, заполняем в _ready() -----------------------
var _score      : Node                    # singleton Score
var _game       : Node2D
var _ui_layer   : CanvasLayer
var _sound      : AudioStreamPlayer
var _scoreboard : Control                   # может быть null

# --------------------------- READY ---------------------------
func _ready() -> void:
		# убеждаемся, что сигнал подключён ровно один раз
		if not body_entered.is_connected(_on_body_entered):
				body_entered.connect(_on_body_entered)

		_score      = get_node("/root/Score")
		_game       = get_tree().root.get_node("Game") as Node2D
		_ui_layer   = _game.get_node("UI") as CanvasLayer
		_sound      = _game.get_node("GoalSound") as AudioStreamPlayer
		_scoreboard = _ui_layer.get_node_or_null("Scoreboard") as Control

# ------------------- ОБРАБОТКА ГОЛА --------------------------
func _on_body_entered(body: Node) -> void:
		if not (body is RigidBody2D and body.is_in_group("ball")):
				return                        # не наш мяч

		# 1️⃣ Обновляем глобальный счёт
		if is_right_goal:
				_score.left += 1
		else:
				_score.right += 1

		# 2️⃣ Обновляем интерфейс
		_update_ui()

		# 3️⃣ Играем звук
		if _sound:
				_sound.play()

		# 4️⃣ Показываем рекламу (один раз за матч)
		_try_show_ad_once()

		# 5️⃣ Перезапускаем раунд (через deferred, чтобы обработчик закончился)
		_game.call_deferred("reset_round")

# ---------------------- ВСПОМОГАТЕЛЬНЫЕ ----------------------
func _update_ui() -> void:
		# Новое табло
		if _scoreboard and _scoreboard.has_method("set_scores"):
				_scoreboard.set_scores(_score.left, _score.right)

		# Старые метки (оставлены для совместимости)
		var lbl_left  := _ui_layer.get_node_or_null("ScoreLeft")  as Label
		var lbl_right := _ui_layer.get_node_or_null("ScoreRight") as Label
		if lbl_left:
				lbl_left.text  = str(_score.left)
		if lbl_right:
				lbl_right.text = str(_score.right)

func _try_show_ad_once() -> void:
		if _score.ad_shown:
				return                      # уже показывали

		if _score.left == 4 or _score.right == 4:
				if Engine.has_singleton("YandexSDK"):   # SDK доступен только в Web-сборке
						YandexSDK.show_ad()
				_score.ad_shown = true
