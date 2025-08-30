extends Control

func _ready():
	# Создаем кнопки для переключения языка
	var lang_container = HBoxContainer.new()
	lang_container.position = Vector2(10, 10)
	add_child(lang_container)
	
	var en_btn = Button.new()
	en_btn.text = "English"
	en_btn.pressed.connect(_switch_to_english)
	lang_container.add_child(en_btn)
	
	var ru_btn = Button.new()
	ru_btn.text = tr("Русский")
	ru_btn.pressed.connect(_switch_to_russian)
	lang_container.add_child(ru_btn)
	
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
	
	var test_rich = RichTextLabel.new()
	test_rich.text = tr("ФИНАЛЬНЫЕ РЕЗУЛЬТАТЫ")
	test_rich.custom_minimum_size = Vector2(200, 50)
	test_container.add_child(test_rich)

func _switch_to_english():
	var locale_manager = get_node("/root/LocaleManager")
	if locale_manager:
		locale_manager.set_lang("en")
		print("Переключено на английский")

func _switch_to_russian():
	var locale_manager = get_node("/root/LocaleManager")
	if locale_manager:
		locale_manager.set_lang("ru")
		print("Переключено на русский")
