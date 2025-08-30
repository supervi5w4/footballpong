extends Node

func _ready():
	print("=== ТЕСТ ЗАЩИТЫ ОТ ОГРОМНЫХ ЗНАЧЕНИЙ ===")
	
	# Ждем инициализацию
	await get_tree().process_frame
	
	# Находим AI ракетку
	var ai_paddle = get_node_or_null("Game/AiPaddle")
	if not ai_paddle:
		print("❌ AI ракетка не найдена!")
		return
	
	print("✅ AI ракетка найдена")
	
	# Тестируем функцию _clamp_y_to_field с огромными значениями
	print("📋 Тест _clamp_y_to_field() с огромными значениями:")
	
	var huge_values = [
		1000000.0,
		-1000000.0,
		999999999.0,
		-999999999.0,
		1e10,
		-1e10
	]
	
	for huge_value in huge_values:
		var result = ai_paddle._clamp_y_to_field(huge_value)
		print("   _clamp_y_to_field(", huge_value, ") = ", result)
		if abs(result - ai_paddle.start_pos.y) < 1.0:
			print("   ✅ Защита работает - вернула start_pos.y")
		else:
			print("   ❌ Защита не работает!")
	
	# Тестируем функцию _predict_intercept с огромными значениями
	print("📋 Тест _predict_intercept() с огромными значениями:")
	
	# Устанавливаем огромную позицию мяча
	if ai_paddle._ball:
		ai_paddle._ball.global_position = Vector2(1000.0, 1e10)
		ai_paddle._ball.linear_velocity = Vector2(-500.0, 1e10)
		
		var result = ai_paddle._predict_intercept()
		print("   _predict_intercept() с огромными значениями = ", result)
		if abs(result.x - ai_paddle.global_position.x) < 1.0 and abs(result.y - ai_paddle.start_pos.y) < 1.0:
			print("   ✅ Защита работает - вернула безопасную позицию")
		else:
			print("   ❌ Защита не работает!")
	
	# Тестируем функцию _predict_intercept_with_spin с огромными значениями
	print("📋 Тест _predict_intercept_with_spin() с огромными значениями:")
	
	if ai_paddle._ball:
		ai_paddle._ball.global_position = Vector2(1000.0, -1e10)
		ai_paddle._ball.linear_velocity = Vector2(-500.0, -1e10)
		ai_paddle._ball.angular_velocity = 1e10
		
		var result = ai_paddle._predict_intercept_with_spin()
		print("   _predict_intercept_with_spin() с огромными значениями = ", result)
		if abs(result.x - ai_paddle.global_position.x) < 1.0 and abs(result.y - ai_paddle.start_pos.y) < 1.0:
			print("   ✅ Защита работает - вернула безопасную позицию")
		else:
			print("   ❌ Защита не работает!")
	
	print("✅ Тест защиты от огромных значений завершен")
	get_tree().quit()
