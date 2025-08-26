# scenes/menu.gd
extends Control

@onready var play_btn : Button = %PlayBtn        # Кнопка «Играть»
@onready var tournament_btn : Button = %TournamentBtn  # Новая кнопка «Турнир»
#@onready var exit_btn : Button = %ExitBtn        # Кнопка «Выход» (если используется)

func _ready() -> void:
	# Подключаем сигналы нажатия на методы
	play_btn.pressed.connect(_on_play_pressed)
	tournament_btn.pressed.connect(_on_tournament_pressed)
	# exit_btn.pressed.connect(_on_exit_pressed)
	
	# Вызываем Game Ready API после загрузки игры
	if YandexSDK.is_working():
		YandexSDK.game_ready()

func _on_play_pressed() -> void:
	# Показываем рекламу перед переходом к игре
	if YandexSDK.is_working():
		YandexSDK.show_interstitial_ad()
		# Ждем завершения показа рекламы
		await YandexSDK.interstitial_ad
	# Устанавливаем current_match в -1 для обычной игры
	Score.current_match = -1
	# Переход к игре
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_tournament_pressed() -> void:
	# Показываем рекламу перед переходом к турниру
	if YandexSDK.is_working():
		YandexSDK.show_interstitial_ad()
		# Ждем завершения показа рекламы
		await YandexSDK.interstitial_ad
	# Переход к сцене выбора команд для турнира (создадим её на следующем шаге)
	get_tree().change_scene_to_file("res://scenes/tournament_menu.tscn")

func _on_exit_pressed() -> void:
	# Завершить игру
	get_tree().quit()
