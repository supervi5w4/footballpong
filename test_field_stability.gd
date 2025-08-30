extends Node

func _ready():
	print("=== ТЕСТ СТАБИЛЬНОСТИ ГРАНИЦ ПОЛЯ ===")
	
	# Ждем инициализацию
	await get_tree().process_frame
	
	# Находим AI ракетку
	var ai_paddle = get_node_or_null("Game/AiPaddle")
	if not ai_paddle:
		print("❌ AI ракетка не найдена!")
		return
	
	print("✅ AI ракетка найдена")
	
	# Тестируем функцию get_field_rect() в различных условиях
	print("📋 Тест get_field_rect() в нормальных условиях:")
	var normal_rect = ai_paddle.get_field_rect()
	print("   Нормальные границы: ", normal_rect)
	print("   position: ", normal_rect.position)
	print("   size: ", normal_rect.size)
	
	# Проверяем, что границы разумные
	if normal_rect.size.x > 0 and normal_rect.size.y > 0 and normal_rect.size.x < 3000.0 and normal_rect.size.y < 2000.0:
		print("   ✅ Границы разумные")
	else:
		print("   ❌ Границы неразумные!")
	
	# Тестируем функцию _clamp_y_to_field с различными значениями
	print("📋 Тест _clamp_y_to_field() с различными значениями:")
	
	var test_values = [
		0.0,
		100.0,
		500.0,
		1000.0,
		-100.0,
		-500.0,
		2000.0,
		-2000.0
	]
	
	for test_value in test_values:
		var result = ai_paddle._clamp_y_to_field(test_value)
		print("   _clamp_y_to_field(", test_value, ") = ", result)
		
		# Проверяем, что результат в разумных пределах
		if result >= 100.0 and result <= 980.0:
			print("   ✅ Результат в разумных пределах")
		else:
			print("   ❌ Результат вне разумных пределов!")
	
	# Тестируем функции предсказания с нормальными значениями
	print("📋 Тест функций предсказания:")
	
	if ai_paddle._ball:
		# Устанавливаем нормальную позицию мяча
		ai_paddle._ball.global_position = Vector2(1000.0, 500.0)
		ai_paddle._ball.linear_velocity = Vector2(-500.0, 100.0)
		ai_paddle._ball.angular_velocity = 0.0
		
		var intercept_result = ai_paddle._predict_intercept()
		print("   _predict_intercept() = ", intercept_result)
		
		# Проверяем, что результат разумный
		if abs(intercept_result.x - ai_paddle.global_position.x) < 1.0 and abs(intercept_result.y) < 2000.0:
			print("   ✅ Результат предсказания разумный")
		else:
			print("   ❌ Результат предсказания неразумный!")
		
		# Тестируем с небольшим спином
		ai_paddle._ball.angular_velocity = 10.0
		var spin_result = ai_paddle._predict_intercept_with_spin()
		print("   _predict_intercept_with_spin() = ", spin_result)
		
		# Проверяем, что результат разумный
		if abs(spin_result.x - ai_paddle.global_position.x) < 1.0 and abs(spin_result.y) < 2000.0:
			print("   ✅ Результат предсказания со спином разумный")
		else:
			print("   ❌ Результат предсказания со спином неразумный!")
	
	print("✅ Тест стабильности границ поля завершен")
	get_tree().quit()
