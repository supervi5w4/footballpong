extends Node
class_name AudioManager

var _last_play: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func _load_stream(name: String) -> AudioStream:
	var base: String = "res://AudioStreamPlayer/%s" % name
	for ext in [".ogg", ".wav", ".mp3"]:
		var p: String = base + ext
		if ResourceLoader.exists(p):
			return load(p)
	push_warning("AudioManager: stream not found: " + name)
	return null

func play(
	name: String,
	world_pos: Vector2 = Vector2.ZERO,
	base_db: float = 0.0,
	pitch_var: float = 0.05,
	vol_var_db: float = 3.0,
	cooldown_s: float = 0.5,
	bus: String = "Master"
) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var last: float = float(_last_play.get(name, -9999.0))
	if now - last < cooldown_s:
		return

	var stream: AudioStream = _load_stream(name)
	if stream == null:
		return

	_last_play[name] = now

	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus

	var pitch: float = 1.0 + _rng.randf_range(-pitch_var, pitch_var)
	var vol: float = base_db + _rng.randf_range(-vol_var_db, vol_var_db)

	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		var dist: float = world_pos.distance_to(cam.global_position)
		var vp: Vector2 = get_viewport().get_visible_rect().size
		var far_thresh: float = max(vp.x, vp.y) * 0.6
		if dist > far_thresh * 1.0:
			vol -= 3.0
		elif dist > far_thresh * 0.75:
			vol -= 2.0

	p.pitch_scale = pitch
	p.volume_db = vol

	add_child(p)
	p.finished.connect(func(): p.queue_free())
	p.play()
