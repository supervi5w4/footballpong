extends Node

func _ready():
	print("=== ПРОСТОЙ ТЕСТ КОМПИЛЯЦИИ ===")
	
	# Проверяем базовые функции TranslationServer
	print("Текущая локаль: ", TranslationServer.get_locale())
	
	# Тестируем функцию tr()
	var test_text = tr("Быстрая игра")
	print("Тест перевода: '", test_text, "'")
	
	# Проверяем LocaleManager
	var locale_manager = get_node("/root/LocaleManager")
	if locale_manager:
		print("✅ LocaleManager найден и работает")
	else:
		print("❌ LocaleManager не найден")
	
	print("=== ТЕСТ ЗАВЕРШЕН ===")
