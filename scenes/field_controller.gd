# ------------------------------------------------------------
# field_controller.gd — Контроллер для управления масштабированием поля
# Отвечает за:
#   - вычисление оптимального масштаба поля на основе размера экрана
#   - позиционирование поля в центре viewport
#   - адаптацию к различным разрешениям экрана
# ------------------------------------------------------------

extends Node
class_name FieldController

signal field_scaled(new_scale: Vector2, new_position: Vector2)

# --- Константы ---
const MIN_MARGIN := 100.0  # Увеличиваем минимальный отступ от краев экрана
const ASPECT_RATIO_TOLERANCE := 0.1  # Допустимое отклонение от пропорций
const BASE_FIELD_SIZE := Vector2(1536, 1080)  # Базовый размер текстуры поля

# --- Переменные ---
var _viewport_size: Vector2 = Vector2.ZERO
var _field_texture_size: Vector2 = Vector2.ZERO
var _current_scale: Vector2 = Vector2.ONE
var _current_position: Vector2 = Vector2.ZERO

# --- Узлы ---
@onready var field_sprite: Sprite2D = null

func _ready() -> void:
	# Ждем один кадр, чтобы viewport был инициализирован
	await get_tree().process_frame
	_calculate_field_scale()

func set_field_sprite(sprite: Sprite2D) -> void:
	"""Устанавливает спрайт поля для управления"""
	field_sprite = sprite
	if field_sprite and field_sprite.texture:
		_field_texture_size = field_sprite.texture.get_size()
		_calculate_field_scale()

func _notification(what: int) -> void:
	"""Обработка системных уведомлений"""
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# При изменении размера окна пересчитываем масштаб
		await get_tree().process_frame
		_calculate_field_scale()

func _calculate_field_scale() -> void:
	"""Вычисляет оптимальный масштаб для поля"""
	var viewport_rect = get_viewport().get_visible_rect()
	_viewport_size = viewport_rect.size
	
	# Используем размер текстуры или базовый размер
	if _field_texture_size == Vector2.ZERO:
		_field_texture_size = BASE_FIELD_SIZE
	
	# Вычисляем доступное пространство с учетом отступов
	var available_size = _viewport_size - Vector2(MIN_MARGIN * 2, MIN_MARGIN * 2)
	
	# Вычисляем масштаб по X и Y отдельно
	var scale_x = available_size.x / _field_texture_size.x
	var scale_y = available_size.y / _field_texture_size.y
	
	# Используем меньший масштаб, чтобы сохранить пропорции и не выйти за границы
	var uniform_scale = min(scale_x, scale_y)
	
	# Проверяем, что масштаб не меньше минимального и не больше максимального
	uniform_scale = clamp(uniform_scale, 0.3, 2.0)
	
	_current_scale = Vector2(uniform_scale, uniform_scale)
	_current_position = _viewport_size * 0.5
	
	# Применяем масштаб к спрайту поля
	if field_sprite:
		field_sprite.scale = _current_scale
		field_sprite.position = _current_position
		# Убеждаемся, что поле находится на заднем плане
		field_sprite.z_index = -1
	
	print("Field Controller:")
	print("  Viewport size: ", _viewport_size)
	print("  Field texture size: ", _field_texture_size)
	print("  Available size: ", available_size)
	print("  Calculated scale: ", _current_scale)
	print("  Field position: ", _current_position)
	
	# Отправляем сигнал об изменении масштаба
	field_scaled.emit(_current_scale, _current_position)

func get_field_scale() -> Vector2:
	"""Возвращает текущий масштаб поля"""
	return _current_scale

func get_field_position() -> Vector2:
	"""Возвращает текущую позицию поля"""
	return _current_position

func get_field_bounds() -> Rect2:
	"""Возвращает границы поля в мировых координатах"""
	if not field_sprite or not field_sprite.texture:
		return Rect2()
	
	var texture_size = _field_texture_size * _current_scale
	var half_size = texture_size * 0.5
	
	return Rect2(
		_current_position - half_size,
		texture_size
	)

func get_viewport_size() -> Vector2:
	"""Возвращает размер viewport"""
	return _viewport_size

func is_field_visible() -> bool:
	"""Проверяет, полностью ли поле видимо на экране"""
	var bounds = get_field_bounds()
	var viewport_rect = Rect2(Vector2.ZERO, _viewport_size)
	return viewport_rect.encloses(bounds)
