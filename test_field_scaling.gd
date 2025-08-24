# ------------------------------------------------------------
# test_field_scaling.gd — Тестовый скрипт для проверки масштабирования поля
# Используется для отладки и проверки работы FieldController
# ------------------------------------------------------------

extends Node

@onready var field_controller: FieldController = null
@onready var field_sprite: Sprite2D = null

func _ready() -> void:
	# Находим контроллер поля и спрайт
	field_controller = get_node_or_null("../FieldController")
	field_sprite = get_node_or_null("../Field")
	
	if field_controller and field_sprite:
		print("Test: Field scaling test initialized")
		field_controller.field_scaled.connect(_on_field_scaled)
		
		# Запускаем тест через секунду
		await get_tree().create_timer(1.0).timeout
		run_scaling_test()
	else:
		print("Test: Failed to find field controller or sprite")

func run_scaling_test() -> void:
	"""Запускает тест масштабирования"""
	print("\n=== Field Scaling Test ===")
	
	if not field_controller:
		print("Test: Field controller not found")
		return
	
	var viewport_size = field_controller.get_viewport_size()
	var field_scale = field_controller.get_field_scale()
	var field_position = field_controller.get_field_position()
	var field_bounds = field_controller.get_field_bounds()
	var is_visible = field_controller.is_field_visible()
	
	print("Test Results:")
	print("  Viewport size: ", viewport_size)
	print("  Field scale: ", field_scale)
	print("  Field position: ", field_position)
	print("  Field bounds: ", field_bounds)
	print("  Field fully visible: ", is_visible)
	
	# Проверяем, что поле помещается в viewport
	if is_visible:
		print("  ✓ Field fits within viewport")
	else:
		print("  ✗ Field does not fit within viewport")
	
	# Проверяем, что масштаб разумен
	if field_scale.x > 0.1 and field_scale.x < 10.0:
		print("  ✓ Field scale is reasonable")
	else:
		print("  ✗ Field scale is out of reasonable range: ", field_scale)

func _on_field_scaled(new_scale: Vector2, new_position: Vector2) -> void:
	"""Обработчик изменения масштаба поля"""
	print("Test: Field scaled to ", new_scale, " at ", new_position)
	
	# Запускаем тест после изменения масштаба
	await get_tree().create_timer(0.1).timeout
	run_scaling_test()
