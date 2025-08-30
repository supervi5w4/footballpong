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
			# Всегда переводим текст, независимо от того, изменился ли он
			var original_text = node.text
			var translated_text = tr(original_text)
			node.text = translated_text
			print("Переведен элемент: '", original_text, "' -> '", translated_text, "'")
	elif node is OptionButton:
		if "text" in node and typeof(node.text) == TYPE_STRING and node.text != "":
			var original_text = node.text
			var translated_text = tr(original_text)
			node.text = translated_text
			print("Переведен OptionButton: '", original_text, "' -> '", translated_text, "'")
		for i in node.item_count:
			var original_item_text = node.get_item_text(i)
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
