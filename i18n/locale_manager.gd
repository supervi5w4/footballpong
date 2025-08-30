extends Node

func _ready() -> void:
	_auto_detect_web_language()
	translate_tree(get_tree().root)
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func set_lang(lang: String) -> void:
	print("LocaleManager: переключаем на язык ", lang)
	TranslationServer.set_locale(lang)
	print("LocaleManager: локаль установлена на ", TranslationServer.get_locale())
	translate_tree(get_tree().root)
	print("LocaleManager: дерево переведено")

func translate_tree(root: Node) -> void:
	if not root: return
	_translate_node(root)
	for child in root.get_children():
		translate_tree(child)

func _translate_node(node: Node) -> void:
	# Проверяем каждый тип ноды отдельно для лучшей совместимости
	if node is Label or node is Button or node is RichTextLabel or node is CheckBox or node is CheckButton or node is LineEdit or node is TextEdit or node is MenuButton:
		if "text" in node and typeof(node.text) == TYPE_STRING and node.text != "":
			# Проверяем, есть ли метаданные с ключом перевода
			if not node.has_meta("loc_key"):
				# Сохраняем оригинальный текст как ключ перевода
				node.set_meta("loc_key", node.text)
			
			# Используем сохраненный ключ для перевода
			var key = node.get_meta("loc_key")
			var translated_text = tr(key)
			node.text = translated_text
			print("Переведен элемент: '", key, "' -> '", translated_text, "'")
	elif node is OptionButton:
		if "text" in node and typeof(node.text) == TYPE_STRING and node.text != "":
			# Проверяем, есть ли метаданные с ключом перевода
			if not node.has_meta("loc_key"):
				# Сохраняем оригинальный текст как ключ перевода
				node.set_meta("loc_key", node.text)
			
			# Используем сохраненный ключ для перевода
			var key = node.get_meta("loc_key")
			var translated_text = tr(key)
			node.text = translated_text
			print("Переведен OptionButton: '", key, "' -> '", translated_text, "'")
		
		# Обрабатываем пункты OptionButton
		if not node.has_meta("tr_items"):
			# Сохраняем оригинальные пункты при первом обращении
			var original_items = []
			for i in node.item_count:
				original_items.append(node.get_item_text(i))
			node.set_meta("tr_items", original_items)
		
		# Переводим пункты из сохраненного массива
		var original_items = node.get_meta("tr_items")
		for i in range(min(original_items.size(), node.item_count)):
			var original_item_text = original_items[i]
			var translated_item_text = tr(original_item_text)
			node.set_item_text(i, translated_item_text)
			print("Переведен пункт OptionButton: '", original_item_text, "' -> '", translated_item_text, "'")

func _on_node_added(node: Node) -> void:
	translate_tree(node)

func _auto_detect_web_language() -> void:
	if Engine.has_singleton("JavaScriptBridge"):
		var result = JavaScriptBridge.eval("navigator.language || navigator.userLanguage")
		if result != null:
			var lang = str(result)
			if lang and lang.begins_with("ru"):
				TranslationServer.set_locale("ru")
			else:
				TranslationServer.set_locale("en")
		else:
			TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale("en")
