extends CanvasLayer

var hp_fill: ColorRect
var hp_label: Label
var combo_label: Label
var info_label: Label
var result_label: Label
var font: Font


func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Noto Sans CJK SC", "Noto Sans CJK", "Noto Serif CJK SC"])
	var title := _label(Vector2(24, 16), "第一关  猎归", 28)
	title.modulate = Color("#f3efe4")
	hp_label = _label(Vector2(24, 52), "林狩  100 / 100", 18)
	var bg := ColorRect.new()
	bg.position = Vector2(24, 78)
	bg.size = Vector2(280, 14)
	bg.color = Color("#1a1410")
	add_child(bg)
	hp_fill = ColorRect.new()
	hp_fill.position = Vector2(24, 78)
	hp_fill.size = Vector2(280, 14)
	hp_fill.color = Color("#c4473a")
	add_child(hp_fill)
	combo_label = _label(Vector2(24, 100), "J 攻击", 20)
	info_label = _label(Vector2(24, 128), "荆丛猎场  ·  猎物 3", 18)
	var hint := _label(Vector2(24, 668), "A/D ←→ 移动   ↑↓ 纵深（S 也向下）   W 跳   J 攻击\n第三击起手按住 ↑ 向后投，按住 ↓ 向前投；松开则击倒。R 重开", 16)
	hint.size = Vector2(1230, 48)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color("#efe8d6")
	result_label = _label(Vector2(360, 280), "", 32)
	result_label.visible = false
	result_label.size = Vector2(560, 160)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


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
	add_child(label)
	return label
