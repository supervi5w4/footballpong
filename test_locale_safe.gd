extends Node

func _ready():
	print("=== БЕЗОПАСНЫЙ ТЕСТ LOCALE MANAGER ===")
	
	# Ждем немного, чтобы все синглтоны загрузились
	await get_tree().process_frame
	
	# Проверяем базовые функции TranslationServer
	print("Текущая локаль: ", TranslationServer.get_locale())
	
	# Тестируем функцию tr() безопасно
	var test_text = tr("Быстрая игра")
	print("Тест перевода: '", test_text, "'")
	
	# Проверяем LocaleManager безопасно
	var locale_manager = get_node_or_null("/root/LocaleManager")
	if locale_manager:
		print("✅ LocaleManager найден")
		
		# Тестируем смену языка безопасно
		try:
			locale_manager.set_lang("en")
			print("✅ Смена на английский успешна")
		except:
			print("❌ Ошибка при смене на английский")
			
		try:
			locale_manager.set_lang("ru")
			print("✅ Смена на русский успешна")
		except:
			print("❌ Ошибка при смене на русский")
			
		# Возвращаем английский
		locale_manager.set_lang("en")
		
	else:
		print("❌ LocaleManager не найден")
	
	print("=== ТЕСТ ЗАВЕРШЕН ===")
