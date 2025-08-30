# scenes/menu.gd
extends Control

@onready var play_btn : Button = %PlayBtn        # Кнопка «Играть»
@onready var tournament_btn : Button = %TournamentBtn  # Новая кнопка «Турнир»
@onready var lang_btn : Button = %LangButton     # Кнопка переключения языка
#@onready var exit_btn : Button = %ExitBtn        # Кнопка «Выход» (если используется)

func _ready() -> void:
	# Подключаем сигналы нажатия на методы
	play_btn.pressed.connect(_on_play_pressed)
	tournament_btn.pressed.connect(_on_tournament_pressed)
	lang_btn.pressed.connect(_on_lang_button_pressed)
	# exit_btn.pressed.connect(_on_exit_pressed)
	
	# Вызываем Game Ready API после загрузки игры
	if YandexSDK.is_working():
		YandexSDK.game_ready()
	
	# Опционально: принудительно переводим дерево сцены
	var locale_manager = get_node("/root/LocaleManager")
	if locale_manager:
		locale_manager.translate_tree(get_tree().root)
	
	# Обновляем текст кнопки языка
	_update_lang_button_text()

func _on_play_pressed() -> void:
	# Устанавливаем current_match в -1 для обычной игры
	Score.current_match = -1
	# Переход к игре
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_tournament_pressed() -> void:
	# Переход к сцене выбора команд для турнира (создадим её на следующем шаге)
	get_tree().change_scene_to_file("res://scenes/tournament_menu.tscn")

func _on_lang_button_pressed() -> void:
	print("=== КНОПКА ПЕРЕКЛЮЧЕНИЯ ЯЗЫКА НАЖАТА ===")
	
	var cur := TranslationServer.get_locale()
	var next := "ru" if cur == "en" else "en"
	print("Текущий язык: ", cur, ", переключаем на: ", next)
	
	# Прямое переключение через TranslationServer
	TranslationServer.set_locale(next)
	print("Переключен язык с ", cur, " на ", next)
	
	# Проверяем результат
	var new_locale = TranslationServer.get_locale()
	print("Проверка: новая локаль = ", new_locale)
	
	# Тестируем перевод
	var test_text = tr("Быстрая игра")
	print("Тест перевода 'Быстрая игра' = '", test_text, "'")
	
	# Обновляем все элементы меню вручную
	print("Обновляем элементы меню вручную...")
	_update_menu_elements()
	
	# Обновляем текст кнопки после смены языка
	_update_lang_button_text()
	
	print("Переключение завершено")

func _update_menu_elements() -> void:
	# Обновляем кнопки
	if play_btn:
		play_btn.text = tr("Быстрая игра")
		print("PlayBtn обновлен: ", play_btn.text)
	
	if tournament_btn:
		tournament_btn.text = tr("Турнир")
		print("TournamentBtn обновлен: ", tournament_btn.text)
	
	# Обновляем RichTextLabel с инструкциями
	var instructions_label = get_node_or_null("HowToPlayPanel/VBoxContainer/RichTextLabel")
	if instructions_label:
		instructions_label.text = tr("• [b]Управление:[/b] стрелки ← ↑ ↓ → — перемещайте ракетку.  \n\n• [b]Быстрая игра:[/b] один полноценный матч — сыграйте и сразу узнайте результат.\n\n• [b]Турнир:[/b] серия из 6 матчей — пройдите дистанцию и докажите стабильность.")
		print("InstructionsLabel обновлен")

func _update_lang_button_text() -> void:
	var current_lang := TranslationServer.get_locale()
	# Показываем противоположный язык (что будет при нажатии)
	var button_text := "RU" if current_lang == "en" else "EN"
	lang_btn.text = button_text
	print("Кнопка обновлена: ", button_text, " (текущий язык: ", current_lang, ")")
	
	# Проверяем, что кнопка действительно обновилась
	print("Проверка кнопки: text = '", lang_btn.text, "', current_lang = ", current_lang)

func _on_exit_pressed() -> void:
	# Завершить игру
	get_tree().quit()
