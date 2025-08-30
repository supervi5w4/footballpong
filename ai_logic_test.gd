# Тест логики AI ракетки без запуска Godot
extends Node

func _ready():
	print("=== ТЕСТ ЛОГИКИ AI РАКЕТКИ ===")
	
	# Симулируем основные параметры AI
	var ai_pos = Vector2(1612, 650)
	var ball_pos = Vector2(958, 663)
	var player_pos = Vector2(293, 656)
	
	print("📋 Позиции:")
	print("   AI: ", ai_pos)
	print("   Мяч: ", ball_pos)
	print("   Игрок: ", player_pos)
	
	# Проверяем расстояние между AI и мячом
	var distance_to_ball = ai_pos.distance_to(ball_pos)
	print("📋 Расстояние AI до мяча: ", distance_to_ball)
	
	# Проверяем, на какой стороне находится мяч
	var center_x = 960  # Примерный центр поля
	var ball_on_ai_side = ball_pos.x > center_x
	print("📋 Мяч на стороне AI: ", ball_on_ai_side)
	
	# Симулируем движение мяча
	var ball_velocity = Vector2(500, 0)  # Мяч движется вправо
	print("📋 Скорость мяча: ", ball_velocity)
	
	# Проверяем, движется ли мяч к AI
	var ai_defends_right = true
	var ball_heading_to_ai = (ai_defends_right and ball_velocity.x > 0) or (not ai_defends_right and ball_velocity.x < 0)
	print("📋 Мяч движется к AI: ", ball_heading_to_ai)
	
	# Симулируем предсказание точки перехвата
	var intercept_pos = predict_intercept(ai_pos, ball_pos, ball_velocity)
	print("📋 Предсказанная точка перехвата: ", intercept_pos)
	
	# Проверяем, нужно ли AI двигаться
	var movement_needed = ai_pos.distance_to(intercept_pos) > 10
	print("📋 Нужно ли AI двигаться: ", movement_needed)
	
	if movement_needed:
		var direction = (intercept_pos - ai_pos).normalized()
		var speed = 850.0  # Базовая скорость AI
		var velocity = direction * speed
		print("📋 Рекомендуемая скорость AI: ", velocity)
		print("✅ AI должен двигаться!")
	else:
		print("⚠️ AI не должен двигаться")

func predict_intercept(ai_pos: Vector2, ball_pos: Vector2, ball_velocity: Vector2) -> Vector2:
	"""Простое предсказание точки перехвата"""
	var ai_x = ai_pos.x
	var ball_x = ball_pos.x
	var ball_vx = ball_velocity.x
	
	if abs(ball_vx) < 0.001:
		return ball_pos
	
	var time_to_ai = (ai_x - ball_x) / ball_vx
	
	if time_to_ai < 0:
		return ball_pos  # Мяч движется в противоположном направлении
	
	var intercept_y = ball_pos.y + ball_velocity.y * time_to_ai
	
	# Ограничиваем Y в пределах поля
	var field_height = 1080
	var margin = 80
	intercept_y = clamp(intercept_y, margin, field_height - margin)
	
	return Vector2(ai_x, intercept_y)
