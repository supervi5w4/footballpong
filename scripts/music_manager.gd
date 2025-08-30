extends Node
class_name MusicManager

var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = "Ambience"
	player.volume_db = -15.0

	var stream = _load_stream("Atmosfera")
	if stream:
		# Включи loop у ресурса, если поддерживается (OGG/MP3 импорт с Loop)
		if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis or stream is AudioStreamWAV:
			stream.loop = true
		player.stream = stream

	# Web-браузеры блокируют звук до первого взаимодействия
	if OS.has_feature("web"):
		get_tree().root.gui_input.connect(_on_any_input)
	else:
		_ensure_playing()

func _on_any_input(_ev: InputEvent) -> void:
	_ensure_playing()

func _ensure_playing() -> void:
	if player and player.stream and not player.playing:
		player.play()

func _load_stream(name: String) -> AudioStream:
	var base: String = "res://AudioStreamPlayer/%s" % name
	for ext in [".ogg", ".mp3", ".wav"]:
		var p: String = base + ext
		if ResourceLoader.exists(p):
			return load(p)
	push_warning("MusicManager: stream not found: " + name)
	return null
