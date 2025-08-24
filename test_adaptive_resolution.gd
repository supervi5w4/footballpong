# ------------------------------------------------------------
# test_adaptive_resolution.gd — Тестовый скрипт для проверки адаптивного разрешения
# ------------------------------------------------------------

extends Node2D

func _ready() -> void:
	print("=== Тест адаптивного разрешения ===")
	
	# Получаем размер viewport
	var viewport_rect = get_viewport().get_visible_rect()
	var viewport_size = viewport_rect.size
	
	print("Размер viewport: ", viewport_size)
	print("Базовый размер: 1920x1080")
	
	# Вычисляем масштаб
	var scale_x = viewport_size.x / 1920.0
	var scale_y = viewport_size.y / 1080.0
	
	print("Масштаб по X: ", scale_x)
	print("Масштаб по Y: ", scale_y)
	
	# Проверяем настройки растягивания
	var stretch_mode = get_viewport().stretch_mode
	var stretch_aspect = get_viewport().stretch_aspect
	
	print("Режим растягивания: ", stretch_mode)
	print("Аспект растягивания: ", stretch_aspect)
	
	# Тестируем позиционирование элементов
	_test_element_positioning(viewport_size, Vector2(scale_x, scale_y))

func _test_element_positioning(viewport_size: Vector2, scale_factor: Vector2) -> void:
	print("\n=== Тест позиционирования элементов ===")
	
	# Базовые позиции для 1920x1080
	var base_positions = {
		"field_center": Vector2(962, 533),
		"player_paddle": Vector2(276, 531),
		"ai_paddle": Vector2(1486, 529),
		"spawn_point": Vector2(880, 529),
		"goal_left": Vector2(93.3764, 532.241),
		"goal_right": Vector2(1673.25, 531.5)
	}
	
	var base_center = Vector2(1920, 1080) * 0.5
	var viewport_center = viewport_size * 0.5
	
	for element_name in base_positions:
		var base_pos = base_positions[element_name]
		
		# Вычисляем смещение от центра
		var offset = base_pos - base_center
		
		# Применяем масштаб к смещению
		var scaled_offset = offset * scale_factor
		
		# Вычисляем новую позицию
		var new_pos = viewport_center + scaled_offset
		
		print(element_name, ":")
		print("  Базовая позиция: ", base_pos)
		print("  Смещение от центра: ", offset)
		print("  Масштабированное смещение: ", scaled_offset)
		print("  Новая позиция: ", new_pos)
		print("")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			print("\n=== Обновленная информация ===")
			var viewport_rect = get_viewport().get_visible_rect()
			print("Текущий размер viewport: ", viewport_rect.size)
			
			# Проверяем, есть ли игровая сцена
			var game_scene = get_node_or_null("../Game")
			if game_scene:
				print("Игровая сцена найдена")
				if game_scene.has_method("_calculate_viewport_scale"):
					game_scene._calculate_viewport_scale()
			else:
				print("Игровая сцена не найдена")
