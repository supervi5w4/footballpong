extends Control

func _ready():
	print("=== ДИАГНОСТИКА ПЕРЕКЛЮЧЕНИЯ ЯЗЫКА ===")
	
	# Проверяем LocaleManager
	var locale_manager = get_node_or_null("/root/LocaleManager")
	if locale_manager:
		print("✅ LocaleManager найден")
	else:
		print("❌ LocaleManager не найден!")
		return
	
	# Проверяем текущую локаль
	var current_locale = TranslationServer.get_locale()
	print("Текущая локаль: ", current_locale)
	
	# Проверяем доступные переводы
	var translations = TranslationServer.get_loaded_locales()
	print("Загруженные переводы: ", translations)
	
	# Тестируем функцию tr()
	var test_text = tr("Быстрая игра")
	print("Тест tr('Быстрая игра'): '", test_text, "'")
	
	# Создаем кнопку для тестирования
	var test_button = Button.new()
	test_button.text = "Тест переключения"
	test_button.position = Vector2(10, 10)
	test_button.pressed.connect(_on_test_button_pressed)
	add_child(test_button)
	
	# Создаем тестовые элементы
	var test_label = Label.new()
	test_label.text = tr("Быстрая игра")
	test_label.position = Vector2(10, 50)
	add_child(test_label)
	
	var test_button2 = Button.new()
	test_button2.text = tr("Турнир")
	test_button2.position = Vector2(10, 80)
	add_child(test_button2)

func _on_test_button_pressed():
	print("--- ПЕРЕКЛЮЧЕНИЕ ЯЗЫКА ---")
	
	var locale_manager = get_node("/root/LocaleManager")
	var current_locale = TranslationServer.get_locale()
	var next_locale = "ru" if current_locale == "en" else "en"
	
	print("Переключаем с ", current_locale, " на ", next_locale)
	
	# Пробуем переключить
	locale_manager.set_lang(next_locale)
	
	# Проверяем результат
	var new_locale = TranslationServer.get_locale()
	print("Новая локаль: ", new_locale)
	
	# Тестируем перевод
	var test_text = tr("Быстрая игра")
	print("Новый тест tr('Быстрая игра'): '", test_text, "'")
	
	# Обновляем элементы на сцене
	var test_label = get_child(1) as Label
	if test_label:
		test_label.text = tr("Быстрая игра")
		print("Label обновлен: ", test_label.text)
	
	var test_button = get_child(2) as Button
	if test_button:
		test_button.text = tr("Турнир")
		print("Button обновлен: ", test_button.text)
