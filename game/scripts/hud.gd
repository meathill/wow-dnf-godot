extends CanvasLayer

const UiFont = preload("res://scripts/ui_font.gd")

var hp_fill: ColorRect
var hp_label: Label
var combo_label: Label
var info_label: Label
var result_label: Label
var font: Font

# Virtual pad axis accumulators (multiple buttons can hold).
var _axis_l := 0
var _axis_r := 0
var _axis_u := 0
var _axis_d := 0


func _ready() -> void:
	VInput.reset()
	layer = 20
	font = UiFont.get_font()
	var title := _label(Vector2(24, 16), "第一关  猎归", 28)
	title.modulate = Color("#f3efe4")
	hp_label = _label(Vector2(24, 52), "林狩  100 / 100", 18)
	var bg := ColorRect.new()
	bg.position = Vector2(24, 78)
	bg.size = Vector2(280, 14)
	bg.color = Color("#1a1410")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	hp_fill = ColorRect.new()
	hp_fill.position = Vector2(24, 78)
	hp_fill.size = Vector2(280, 14)
	hp_fill.color = Color("#c4473a")
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_fill)
	combo_label = _label(Vector2(24, 100), "J 攻击", 20)
	info_label = _label(Vector2(24, 128), "荆丛猎场  ·  猎物 3", 18)
	var hint := _label(
		Vector2(24, 640),
		"A/D 移动，W/S 前后，J 攻击，K 跳跃。第三下按住上或下是投。\n方向键也可移动/前后。空格也可跳。R 重开",
		15
	)
	hint.size = Vector2(900, 56)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color("#efe8d6")
	result_label = _label(Vector2(360, 280), "", 32)
	result_label.visible = false
	result_label.size = Vector2(560, 160)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_virtual_controls()


func set_hp(current: int, maximum: int) -> void:
	hp_label.text = "林狩  %d / %d" % [current, maximum]
	hp_fill.size.x = 280.0 * clampf(float(current) / float(maxi(maximum, 1)), 0.0, 1.0)


func set_combo(text: String) -> void:
	combo_label.text = text


func set_remaining(count: int) -> void:
	info_label.text = "荆丛猎场  ·  猎物 %d" % count


func show_result(text: String) -> void:
	result_label.text = text
	result_label.visible = true


func _label(pos: Vector2, text: String, size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f6f1e6"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _build_virtual_controls() -> void:
	# Left d-pad (bottom-left, clears center playfield).
	var pad_origin := Vector2(36, 470)
	var gap := 62.0
	_axis_btn(pad_origin + Vector2(gap, 0), "↑", func(p): _hold_axis("u", p))
	_axis_btn(pad_origin + Vector2(0, gap), "←", func(p): _hold_axis("l", p))
	_axis_btn(pad_origin + Vector2(gap * 2, gap), "→", func(p): _hold_axis("r", p))
	_axis_btn(pad_origin + Vector2(gap, gap * 2), "↓", func(p): _hold_axis("d", p))

	# Right action buttons.
	_action_btn(Vector2(1120, 520), "J", Color("#c4473a"), func(p): VInput.attack_held = p)
	_action_btn(Vector2(1020, 580), "K", Color("#3a6fc4"), func(p): VInput.jump_held = p)


func _axis_btn(pos: Vector2, caption: String, on_hold: Callable) -> void:
	var btn := _make_pad_button(pos, Vector2(56, 56), caption, Color(0.12, 0.14, 0.16, 0.72))
	btn.button_down.connect(func(): on_hold.call(true))
	btn.button_up.connect(func(): on_hold.call(false))


func _action_btn(pos: Vector2, caption: String, color: Color, on_hold: Callable) -> void:
	var c := Color(color.r, color.g, color.b, 0.78)
	var btn := _make_pad_button(pos, Vector2(72, 72), caption, c)
	btn.button_down.connect(func(): on_hold.call(true))
	btn.button_up.connect(func(): on_hold.call(false))


func _make_pad_button(pos: Vector2, size: Vector2, caption: String, color: Color) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = size
	btn.text = caption
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color("#f6f1e6"))
	btn.add_theme_color_override("font_pressed_color", Color("#ffffff"))
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(color.r, color.g, color.b, minf(color.a + 0.2, 1.0))
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(btn)
	return btn


func _hold_axis(which: String, pressed: bool) -> void:
	var delta := 1 if pressed else -1
	match which:
		"l":
			_axis_l = maxi(_axis_l + delta, 0)
		"r":
			_axis_r = maxi(_axis_r + delta, 0)
		"u":
			_axis_u = maxi(_axis_u + delta, 0)
		"d":
			_axis_d = maxi(_axis_d + delta, 0)
	var mx := 0.0
	var my := 0.0
	if _axis_l > 0:
		mx -= 1.0
	if _axis_r > 0:
		mx += 1.0
	if _axis_u > 0:
		my -= 1.0
	if _axis_d > 0:
		my += 1.0
	VInput.set_move_x(mx)
	VInput.set_move_y(my)
