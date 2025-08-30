extends Node

func _ready():
	print("=== ТЕСТ ПЕРЕВОДОВ ===")
	
	# Проверяем текущую локаль
	print("Текущая локаль: ", TranslationServer.get_locale())
	
	# Тестируем переводы
	var test_keys = [
		"Быстрая игра",
		"Турнир", 
		"В меню",
		"ФИНАЛЬНЫЕ РЕЗУЛЬТАТЫ",
		"Поздравляем — вы заняли 1-е место!"
	]
	
	for key in test_keys:
		var translated = tr(key)
		print("'", key, "' -> '", translated, "'")
	
	# Тестируем LocaleManager
	print("\n=== ТЕСТ LOCALE MANAGER ===")
	var locale_manager = get_node("/root/LocaleManager")
	if locale_manager:
		print("LocaleManager найден!")
		
		# Тестируем смену на русский
		print("Переключаем на русский...")
		locale_manager.set_lang("ru")
		print("Новая локаль: ", TranslationServer.get_locale())
		
		for key in test_keys:
			var translated = tr(key)
			print("'", key, "' -> '", translated, "'")
		
		# Возвращаем английский
		print("Переключаем на английский...")
		locale_manager.set_lang("en")
		print("Новая локаль: ", TranslationServer.get_locale())
		
		for key in test_keys:
			var translated = tr(key)
			print("'", key, "' -> '", translated, "'")
	else:
		print("❌ LocaleManager НЕ найден!")
