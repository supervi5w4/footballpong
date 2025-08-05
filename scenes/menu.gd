# scenes/menu.gd
extends Control

@onready var play_btn : Button = %PlayBtn        # Кнопка «Играть»
@onready var tournament_btn : Button = %TournamentBtn  # Новая кнопка «Турнир»
#@onready var exit_btn : Button = %ExitBtn        # Кнопка «Выход» (если используется)

func _ready() -> void:
	# Подключаем сигналы нажатия к методам
	play_btn.pressed.connect(_on_play_pressed)
	tournament_btn.pressed.connect(_on_tournament_pressed)
	# exit_btn.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	# Переход к игре
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_tournament_pressed() -> void:
	# Переход к сцене выбора команд для турнира (создадим её на следующем шаге)
	get_tree().change_scene_to_file("res://scenes/tournament_menu.tscn")

func _on_exit_pressed() -> void:
	# Завершить игру
	get_tree().quit()
