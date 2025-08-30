extends Control

func _ready():
	print("=== ТЕСТ КНОПКИ ПЕРЕКЛЮЧЕНИЯ ЯЗЫКА ===")
	
	# Создаем кнопку переключения языка
	var lang_button = Button.new()
	lang_button.text = "EN / RU"
	lang_button.position = Vector2(10, 10)
	lang_button.pressed.connect(_on_lang_button_pressed)
	add_child(lang_button)
	
	# Создаем тестовые элементы для демонстрации перевода
	var test_container = VBoxContainer.new()
	test_container.position = Vector2(10, 60)
	add_child(test_container)
	
	var test_label = Label.new()
	test_label.text = tr("Быстрая игра")
	test_container.add_child(test_label)
	
	var test_button = Button.new()
	test_button.text = tr("Турнир")
	test_container.add_child(test_button)
	
	# Показываем текущий язык
	var current_lang = TranslationServer.get_locale()
	print("Текущий язык: ", current_lang)
	print("Кнопка показывает: ", lang_button.text)

func _on_lang_button_pressed():
	var cur := TranslationServer.get_locale()
	var next := "ru" if cur == "en" else "en"
	var locale_manager = get_node("/root/LocaleManager")
	if locale_manager:
		locale_manager.set_lang(next)
		print("Переключен язык с ", cur, " на ", next)
		
		# Обновляем текст кнопки
		var button_text := "RU" if next == "en" else "EN"
		var lang_button = get_child(0) as Button
		if lang_button:
			lang_button.text = button_text
			print("Кнопка обновлена: ", button_text)
	else:
		print("❌ LocaleManager не найден!")
