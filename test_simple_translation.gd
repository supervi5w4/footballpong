extends Control

func _ready():
	print("=== ПРОСТОЙ ТЕСТ ПЕРЕВОДОВ ===")
	
	# Проверяем базовые функции
	print("Текущая локаль: ", TranslationServer.get_locale())
	
	# Тестируем tr() функцию
	var test1 = tr("Быстрая игра")
	var test2 = tr("Турнир")
	print("tr('Быстрая игра') = '", test1, "'")
	print("tr('Турнир') = '", test2, "'")
	
	# Создаем простую кнопку для тестирования
	var button = Button.new()
	button.text = "Переключить язык"
	button.position = Vector2(10, 10)
	button.pressed.connect(_on_button_pressed)
	add_child(button)
	
	# Создаем тестовые элементы
	var label = Label.new()
	label.text = tr("Быстрая игра")
	label.position = Vector2(10, 50)
	add_child(label)
	
	var button2 = Button.new()
	button2.text = tr("Турнир")
	button2.position = Vector2(10, 80)
	add_child(button2)

func _on_button_pressed():
	print("--- ПЕРЕКЛЮЧЕНИЕ ---")
	
	# Получаем LocaleManager
	var locale_manager = get_node_or_null("/root/LocaleManager")
	if not locale_manager:
		print("❌ LocaleManager не найден!")
		return
	
	# Переключаем язык
	var current = TranslationServer.get_locale()
	var next = "ru" if current == "en" else "en"
	
	print("Переключаем с ", current, " на ", next)
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
	
	var button2 = get_child(2) as Button
	if button2:
		button2.text = tr("Турнир")
		print("Button2 обновлен: ", button2.text)
