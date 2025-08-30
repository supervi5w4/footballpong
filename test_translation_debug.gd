extends Control

func _ready():
	print("=== ОТЛАДОЧНЫЙ ТЕСТ ПЕРЕВОДОВ ===")
	
	# Проверяем базовые функции
	print("Текущая локаль: ", TranslationServer.get_locale())
	
	# Проверяем загруженные переводы
	var locales = TranslationServer.get_loaded_locales()
	print("Загруженные переводы: ", locales)
	
	# Проверяем LocaleManager
	var locale_manager = get_node_or_null("/root/LocaleManager")
	if locale_manager:
		print("✅ LocaleManager найден")
	else:
		print("❌ LocaleManager не найден!")
		return
	
	# Тестируем базовые переводы
	var test1 = tr("Быстрая игра")
	var test2 = tr("Турнир")
	print("tr('Быстрая игра') = '", test1, "'")
	print("tr('Турнир') = '", test2, "'")
	
	# Создаем кнопку для переключения
	var switch_button = Button.new()
	switch_button.text = "Переключить язык"
	switch_button.position = Vector2(10, 10)
	switch_button.pressed.connect(_on_switch_pressed)
	add_child(switch_button)
	
	# Создаем тестовые элементы
	var label = Label.new()
	label.text = tr("Быстрая игра")
	label.position = Vector2(10, 50)
	add_child(label)
	
	var button = Button.new()
	button.text = tr("Турнир")
	button.position = Vector2(10, 80)
	add_child(button)
	
	print("Тестовые элементы созданы")

func _on_switch_pressed():
	print("--- ПЕРЕКЛЮЧЕНИЕ ЯЗЫКА ---")
	
	var locale_manager = get_node("/root/LocaleManager")
	var current = TranslationServer.get_locale()
	var next = "ru" if current == "en" else "en"
	
	print("Переключаем с ", current, " на ", next)
	
	# Используем LocaleManager
	locale_manager.set_lang(next)
	
	# Проверяем результат
	var new_locale = TranslationServer.get_locale()
	print("Новая локаль: ", new_locale)
	
	# Тестируем переводы
	var test1 = tr("Быстрая игра")
	var test2 = tr("Турнир")
	print("Новые переводы:")
	print("  tr('Быстрая игра') = '", test1, "'")
	print("  tr('Турнир') = '", test2, "'")
	
	# Обновляем элементы на сцене
	var label = get_child(1) as Label
	if label:
		label.text = tr("Быстрая игра")
		print("Label обновлен: ", label.text)
	
	var button = get_child(2) as Button
	if button:
		button.text = tr("Турнир")
		print("Button обновлен: ", button.text)
	
	# Принудительно переводим все элементы
	print("Принудительно переводим все элементы...")
	locale_manager.translate_tree(self)
	print("Перевод завершен")
