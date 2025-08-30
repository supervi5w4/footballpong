extends Node

func _ready() -> void:
	# Устанавливаем английский по умолчанию
	TranslationServer.set_locale("en")
	translate_tree(get_tree().root)
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func set_lang(lang: String) -> void:
	TranslationServer.set_locale(lang)
	translate_tree(get_tree().root)

func translate_tree(root: Node) -> void:
	if not root: return
	_translate_node(root)
	for child in root.get_children():
		translate_tree(child)

func _translate_node(node: Node) -> void:
	# Проверяем каждый тип ноды отдельно для лучшей совместимости
	if node is Label or node is Button or node is RichTextLabel or node is CheckBox or node is CheckButton or node is LineEdit or node is TextEdit or node is MenuButton:
		if "text" in node and typeof(node.text) == TYPE_STRING and node.text != "":
			node.text = tr(node.text)
	elif node is OptionButton:
		if "text" in node and typeof(node.text) == TYPE_STRING and node.text != "":
			node.text = tr(node.text)
		for i in node.item_count:
			node.set_item_text(i, tr(node.get_item_text(i)))

func _on_node_added(node: Node) -> void:
	translate_tree(node)
