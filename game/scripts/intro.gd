extends Control

## Short original intro before level 1. Skip with J or Enter.

const LEVEL := "res://scenes/level1.tscn"
const PLAYER_SPRITE := "res://sprites/player.png"
const INTRO_SECONDS := 5.5

var elapsed := 0.0
var finished := false
var hunter: TextureRect
var line1: Label
var line2: Label
var line3: Label
var skip_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("#0c1218")
	add_child(bg)

	# Distant green fire glow (original, not a copyrighted skybox)
	var glow := ColorRect.new()
	glow.position = Vector2(780, 40)
	glow.size = Vector2(420, 180)
	glow.color = Color(0.18, 0.72, 0.28, 0.22)
	add_child(glow)
	var glow2 := ColorRect.new()
	glow2.position = Vector2(900, 20)
	glow2.size = Vector2(220, 100)
	glow2.color = Color(0.35, 0.95, 0.4, 0.18)
	add_child(glow2)

	# Ground strip
	var ground := ColorRect.new()
	ground.position = Vector2(0, 520)
	ground.size = Vector2(1280, 200)
	ground.color = Color("#2a3428")
	add_child(ground)

	hunter = TextureRect.new()
	if FileAccess.file_exists(PLAYER_SPRITE):
		hunter.texture = load(PLAYER_SPRITE)
	hunter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hunter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hunter.position = Vector2(160, 360)
	hunter.size = Vector2(140, 240)
	hunter.modulate = Color(1, 1, 1, 0)
	add_child(hunter)

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Noto Sans CJK SC", "Noto Sans CJK", "Noto Serif CJK SC", "Sans"])

	line1 = _make_label(font, Vector2(340, 220), "林狩在荆丛猎场下夹。", 34)
	line2 = _make_label(font, Vector2(340, 280), "天边有一点绿火，他没在意。", 34)
	line3 = _make_label(font, Vector2(340, 340), "夹已经支好——猎场里还有野兽。", 34)
	for L in [line1, line2, line3]:
		L.modulate.a = 0.0

	skip_label = _make_label(font, Vector2(40, 660), "J / Enter 跳过", 18)
	skip_label.modulate = Color("#a8b89a")


func _make_label(font: Font, pos: Vector2, text: String, size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f3efe4"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label


func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	# Fade hunter in
	hunter.modulate.a = clampf(elapsed / 0.8, 0.0, 1.0)
	# Staggered text
	line1.modulate.a = clampf((elapsed - 0.4) / 0.5, 0.0, 1.0)
	line2.modulate.a = clampf((elapsed - 1.4) / 0.5, 0.0, 1.0)
	line3.modulate.a = clampf((elapsed - 2.5) / 0.5, 0.0, 1.0)
	# Auto finish
	if elapsed >= INTRO_SECONDS:
		_go()


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = event.physical_keycode
		if k == KEY_J or k == KEY_ENTER or k == KEY_KP_ENTER:
			_go()


func _go() -> void:
	if finished:
		return
	finished = true
	get_tree().change_scene_to_file(LEVEL)
