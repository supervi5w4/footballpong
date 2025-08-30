extends Node

func _ready():
	print("=== ТЕСТ КОМПИЛЯЦИИ LOCALE MANAGER ===")
	
	# Проверяем, что LocaleManager загружен
	var locale_manager = get_node("/root/LocaleManager")
	if locale_manager:
		print("✅ LocaleManager успешно загружен")
		
		# Проверяем базовые функции
		print("Текущая локаль: ", TranslationServer.get_locale())
		
		# Тестируем перевод
		var test_text = tr("Быстрая игра")
		print("Тестовый перевод: 'Быстрая игра' -> '", test_text, "'")
		
		# Тестируем смену языка
		locale_manager.set_lang("ru")
		print("Локаль после смены: ", TranslationServer.get_locale())
		
		# Возвращаем английский
		locale_manager.set_lang("en")
		print("Локаль возвращена: ", TranslationServer.get_locale())
		
	else:
		print("❌ LocaleManager НЕ найден!")
	
	print("=== ТЕСТ ЗАВЕРШЕН ===")
