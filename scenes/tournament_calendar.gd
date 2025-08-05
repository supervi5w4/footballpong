# scenes/tournament_calendar.gd
extends Control

# Ссылки на элементы интерфейса. Узлы должны иметь отметку Unique Name in Owner.
@onready var matches_list  : VBoxContainer = %MatchesList
@onready var play_next_btn : Button       = %PlayNextBtn

func _ready() -> void:
	# Отрисовываем календарь при запуске сцены
	_render_calendar()
	# Подключаем обработчик нажатия на кнопку
	play_next_btn.pressed.connect(_on_play_next_pressed)

func _render_calendar() -> void:
	# Удаляем старые записи в списке, если они есть
	for child in matches_list.get_children():
		child.queue_free()

	# Проходим по расписанию матчей и выводим каждую игру
	for match in Score.matches:
		var label : Label = Label.new()
		var result_text : String = str(match["score"])  # приводим результат к строке
		# Формируем текст: «домашняя команда — гостевая команда    счёт»
		label.text = "%s — %s    %s" % [match["home"], match["away"], result_text]
		matches_list.add_child(label)

func _on_play_next_pressed() -> void:
	# Пока что находим первый несыгранный матч и выводим его в консоль
	for match in Score.matches:
		if not match["played"]:
			# Здесь позже будет запуск сцены матча игрока
			print("Следующий матч:", match["home"], "vs", match["away"])
			break
