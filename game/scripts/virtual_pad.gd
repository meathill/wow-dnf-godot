extends Control

## Landscape thumb pad. One finger on the d-pad can walk and change depth.
## Attack and jump are separate touches so they can be held together.

const UiFont = preload("res://scripts/ui_font.gd")

var active := false
var _touches := {}
var _btn := 96.0
var _pad_rect := Rect2()
var _up := Rect2()
var _down := Rect2()
var _left := Rect2()
var _right := Rect2()
var _atk_rect := Rect2()
var _jump_rect := Rect2()
var _font: Font
var _style_move: StyleBoxFlat
var _style_move_on: StyleBoxFlat
var _style_atk: StyleBoxFlat
var _style_atk_on: StyleBoxFlat
var _style_jump: StyleBoxFlat
var _style_jump_on: StyleBoxFlat
var _poll := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UiFont.get_font()
	_style_move = _box(Color(0.08, 0.1, 0.12, 0.58))
	_style_move_on = _box(Color(0.85, 0.82, 0.7, 0.78))
	_style_atk = _box(Color(0.77, 0.28, 0.23, 0.8))
	_style_atk_on = _box(Color(0.95, 0.45, 0.32, 0.95))
	_style_jump = _box(Color(0.22, 0.42, 0.75, 0.8))
	_style_jump_on = _box(Color(0.4, 0.62, 0.95, 0.95))
	get_viewport().size_changed.connect(layout)
	call_deferred("layout")


func _process(delta: float) -> void:
	_poll += delta
	if _poll < 0.4:
		return
	_poll = 0.0
	var want := VInput.wants_touch_controls()
	if want != active:
		layout()


func layout() -> void:
	var vis := get_viewport().get_visible_rect()
	position = vis.position
	size = vis.size
	active = VInput.wants_touch_controls()
	visible = active
	if not active:
		_touches.clear()
		VInput.clear_move()
		VInput.attack_held = false
		VInput.jump_held = false
		queue_redraw()
		return
	var insets := VInput.safe_insets(size)
	var margin_l := insets.x + 14.0
	var margin_t := insets.y + 8.0
	var margin_r := insets.z + 14.0
	var margin_b := insets.w + 16.0
	var css := VInput.css_window_size()
	var to_vp := size.y / css.y if css.y > 1.0 else 1.0
	var phone := css.y > 0.0 and css.y <= 540.0
	var desired := (92.0 if phone else 76.0) * to_vp
	var gap_ratio := 0.12
	var width_budget := (size.x * 0.34 - margin_l) / (3.0 + 2.0 * gap_ratio)
	var height_budget := (size.y * 0.62 - margin_b) / (3.0 + 2.0 * gap_ratio)
	var max_fit := minf(width_budget, height_budget)
	if max_fit < 68.0:
		_btn = maxf(max_fit, 48.0)
	else:
		_btn = clampf(desired, 68.0, max_fit)
	var gap := maxf(8.0, _btn * gap_ratio)
	var cluster := _btn * 3.0 + gap * 2.0
	var origin := Vector2(margin_l, size.y - margin_b - cluster)
	_pad_rect = Rect2(origin, Vector2(cluster, cluster))
	_up = Rect2(origin + Vector2(_btn + gap, 0), Vector2(_btn, _btn))
	_left = Rect2(origin + Vector2(0, _btn + gap), Vector2(_btn, _btn))
	_right = Rect2(origin + Vector2((_btn + gap) * 2.0, _btn + gap), Vector2(_btn, _btn))
	_down = Rect2(origin + Vector2(_btn + gap, (_btn + gap) * 2.0), Vector2(_btn, _btn))
	var atk := _btn * 1.28
	var jump := _btn * 1.15
	var right := size.x - margin_r
	var bottom := size.y - margin_b
	_atk_rect = Rect2(Vector2(right - atk, bottom - atk), Vector2(atk, atk))
	_jump_rect = Rect2(Vector2(right - jump - atk * 0.22, _atk_rect.position.y - gap - jump), Vector2(jump, jump))
	# Keep the jump button inside the top safe area.
	if _jump_rect.position.y < margin_t:
		_jump_rect.position.y = margin_t
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var point := _pointer(touch.position)
			var zone := _zone_at(point)
			if zone == "":
				return
			_touches[touch.index] = {"zone": zone, "pos": point}
			_apply()
			get_viewport().set_input_as_handled()
		elif _touches.erase(touch.index):
			_apply()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not _touches.has(drag.index):
			return
		var point := _pointer(drag.position)
		var zone := _zone_at(point)
		if zone == "":
			_touches.erase(drag.index)
		else:
			_touches[drag.index] = {"zone": zone, "pos": point}
		_apply()
		get_viewport().set_input_as_handled()


func _pointer(pos: Vector2) -> Vector2:
	# Screen touches are in viewport space. Pad rects are local to this control.
	return pos - position


func _zone_at(pos: Vector2) -> String:
	var slop := 6.0
	if _jump_rect.grow(slop).has_point(pos):
		return "jump"
	if _atk_rect.grow(slop).has_point(pos):
		return "attack"
	if _pad_rect.grow(slop).has_point(pos):
		return "pad"
	return ""


func _pad_vector(pos: Vector2) -> Vector2:
	var rel := pos - _pad_rect.get_center()
	var dead := _btn * 0.22
	var v := Vector2.ZERO
	if rel.x <= -dead:
		v.x = -1.0
	elif rel.x >= dead:
		v.x = 1.0
	if rel.y <= -dead:
		v.y = -1.0
	elif rel.y >= dead:
		v.y = 1.0
	return v


func _apply() -> void:
	var mx := 0.0
	var my := 0.0
	var atk := false
	var jump := false
	for idx in _touches.keys():
		var entry: Dictionary = _touches[idx]
		var zone := str(entry["zone"])
		var pos: Vector2 = entry["pos"]
		if zone == "attack":
			atk = true
		elif zone == "jump":
			jump = true
		elif zone == "pad":
			var v := _pad_vector(pos)
			mx += v.x
			my += v.y
	VInput.set_move_x(clampf(mx, -1.0, 1.0))
	VInput.set_move_y(clampf(my, -1.0, 1.0))
	VInput.attack_held = atk
	VInput.jump_held = jump
	queue_redraw()


func _draw() -> void:
	if not active or _font == null:
		return
	_paint(_left, "←", "", VInput.move_x < -0.2, _style_move, _style_move_on)
	_paint(_right, "→", "", VInput.move_x > 0.2, _style_move, _style_move_on)
	_paint(_up, "↑", "", VInput.move_y < -0.2, _style_move, _style_move_on)
	_paint(_down, "↓", "", VInput.move_y > 0.2, _style_move, _style_move_on)
	_paint(_atk_rect, "J", "攻击", VInput.attack_held, _style_atk, _style_atk_on)
	_paint(_jump_rect, "K", "跳跃", VInput.jump_held, _style_jump, _style_jump_on)


func _paint(rect: Rect2, caption: String, sub: String, pressed: bool, off: StyleBoxFlat, on: StyleBoxFlat) -> void:
	(on if pressed else off).draw(get_canvas_item(), rect)
	var main_size := int(clampf(rect.size.y * (0.34 if sub != "" else 0.42), 22.0, 48.0))
	var color := Color("#1a140f") if pressed and sub == "" else Color("#f6f1e6")
	if sub == "":
		_draw_centered(caption, rect, main_size, color, 0.0)
		return
	_draw_centered(caption, Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.62)), main_size, Color("#f6f1e6"), 6.0)
	var sub_size := int(clampf(rect.size.y * 0.2, 16.0, 28.0))
	_draw_centered(sub, Rect2(rect.position + Vector2(0, rect.size.y * 0.46), Vector2(rect.size.x, rect.size.y * 0.48)), sub_size, Color("#f6f1e6"), 0.0)


func _draw_centered(text: String, rect: Rect2, font_size: int, color: Color, y_bias: float) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var ascent := _font.get_ascent(font_size)
	var x := rect.position.x + (rect.size.x - width) * 0.5
	var y := rect.position.y + (rect.size.y + ascent) * 0.5 + y_bias
	_font.draw_string(get_canvas_item(), Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style
