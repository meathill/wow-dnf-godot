extends CanvasLayer

const UiFont = preload("res://scripts/ui_font.gd")

var hp_fill: ColorRect
var hp_bg: ColorRect
var hp_label: Label
var combo_label: Label
var info_label: Label
var result_label: Label
var title_label: Label
var hint_label: Label
var font: Font


func _ready() -> void:
	VInput.reset()
	layer = 20
	font = UiFont.get_font()
	title_label = _label(Vector2(24, 16), "第一关  猎归", 28)
	title_label.modulate = Color("#f3efe4")
	hp_label = _label(Vector2(24, 52), "林狩  100 / 100", 18)
	hp_bg = ColorRect.new()
	hp_bg.position = Vector2(24, 78)
	hp_bg.size = Vector2(280, 14)
	hp_bg.color = Color("#1a1410")
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_bg)
	hp_fill = ColorRect.new()
	hp_fill.position = Vector2(24, 78)
	hp_fill.size = Vector2(280, 14)
	hp_fill.color = Color("#c4473a")
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_fill)
	combo_label = _label(Vector2(24, 100), "J 攻击", 20)
	info_label = _label(Vector2(24, 128), "荆丛猎场  ·  猎物 3", 18)
	hint_label = _label(
		Vector2(24, 640),
		"A/D 移动，W/S 前后，J 攻击，K 跳跃。第三下按住上或下是投。\n方向键也可移动/前后。空格也可跳。R 重开",
		15
	)
	hint_label.size = Vector2(900, 56)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color("#efe8d6")
	result_label = _label(Vector2(360, 280), "", 32)
	result_label.visible = false
	result_label.size = Vector2(560, 160)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pad := preload("res://scripts/virtual_pad.gd").new()
	pad.name = "VirtualPad"
	add_child(pad)
	get_viewport().size_changed.connect(_layout_hud)
	call_deferred("_layout_hud")


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
	_place_result(get_viewport().get_visible_rect().size)


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


func _layout_hud() -> void:
	var vis := get_viewport().get_visible_rect().size
	var insets := VInput.safe_insets(vis)
	var pad := get_node_or_null("VirtualPad")
	var phone := pad != null and bool(pad.get("active"))
	var css := VInput.css_window_size()
	var scale := 1.0
	if phone and css.y > 1.0:
		# Keep Chinese labels readable when the 720-tall layout is mapped onto a short phone.
		scale = clampf(14.0 * vis.y / css.y / 18.0, 1.0, 1.35)
	var left := 24.0 + insets.x
	var top := 12.0 + insets.y
	title_label.position = Vector2(left, top)
	_set_font(title_label, int(28 * scale))
	hp_label.position = Vector2(left, top + 36.0 * scale)
	_set_font(hp_label, int(18 * scale))
	var bar_y := top + 64.0 * scale
	hp_bg.position = Vector2(left, bar_y)
	hp_fill.position = Vector2(left, bar_y)
	combo_label.position = Vector2(left, bar_y + 22.0)
	_set_font(combo_label, int(20 * scale))
	info_label.position = Vector2(left, bar_y + 50.0)
	_set_font(info_label, int(18 * scale))
	hint_label.size = Vector2(maxf(240.0, vis.x - left - 24.0 - insets.z), 80.0)
	_set_font(hint_label, int(16 * scale))
	if phone:
		hint_label.position = Vector2(left, info_label.position.y + 30.0 * scale)
	else:
		hint_label.position = Vector2(left, vis.y - 80.0 - insets.w)
	_place_result(vis)


func _set_font(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)


func _place_result(vis: Vector2) -> void:
	result_label.size = Vector2(minf(640.0, maxf(280.0, vis.x - 80.0)), 180.0)
	result_label.position = Vector2((vis.x - result_label.size.x) * 0.5, vis.y * 0.32)
