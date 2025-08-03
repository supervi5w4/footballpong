extends Control

@onready var play_btn : Button = %PlayBtn   # ищем узлы по имени после _ready()
@onready var exit_btn : Button = %ExitBtn

func _ready() -> void:
	# Подключаем сигнал pressed к методам ↓
	play_btn.pressed.connect(_on_play_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
