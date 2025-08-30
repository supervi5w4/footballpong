extends Node

func _ready():
	print("=== ТЕСТ КОМПИЛЯЦИИ AI РАКЕТКИ ===")
	
	# Ждем инициализацию
	await get_tree().process_frame
	
	# Находим AI ракетку
	var ai_paddle = get_node_or_null("Game/AiPaddle")
	if not ai_paddle:
		print("❌ AI ракетка не найдена!")
		return
	
	print("✅ AI ракетка найдена")
	
	# Проверяем, что класс загружен правильно
	if ai_paddle is AiPaddle:
		print("✅ Класс AiPaddle загружен правильно")
	else:
		print("❌ Класс AiPaddle не загружен")
		return
	
	# Проверяем основные методы
	print("📋 Проверка методов:")
	print("   has_method('_physics_process'): ", ai_paddle.has_method("_physics_process"))
	print("   has_method('_ready'): ", ai_paddle.has_method("_ready"))
	print("   has_method('get_field_rect'): ", ai_paddle.has_method("get_field_rect"))
	print("   has_method('_think'): ", ai_paddle.has_method("_think"))
	print("   has_method('_move'): ", ai_paddle.has_method("_move"))
	print("   has_method('_predict_intercept'): ", ai_paddle.has_method("_predict_intercept"))
	print("   has_method('_predict_intercept_with_spin'): ", ai_paddle.has_method("_predict_intercept_with_spin"))
	
	# Проверяем основные свойства
	print("📋 Проверка свойств:")
	print("   skill: ", ai_paddle.skill)
	print("   behaviour_style: ", ai_paddle.behaviour_style)
	print("   defends_right_side: ", ai_paddle.defends_right_side)
	print("   ball_path: ", ai_paddle.ball_path)
	print("   player_path: ", ai_paddle.player_path)
	
	# Тестируем функцию get_field_rect()
	print("📋 Тест get_field_rect():")
	var field_rect = ai_paddle.get_field_rect()
	print("   field_rect: ", field_rect)
	print("   position: ", field_rect.position)
	print("   size: ", field_rect.size)
	
	print("✅ Тест компиляции завершен успешно")
	get_tree().quit()
