extends Node

## Virtual / on-screen control state. Keyboard still works independently in player.

var move_x := 0.0
var move_y := 0.0
var attack_held := false
var jump_held := false

var _attack_was := false
var _jump_was := false
var attack_just := false
var jump_just := false


func _process(_delta: float) -> void:
	attack_just = attack_held and not _attack_was
	jump_just = jump_held and not _jump_was
	_attack_was = attack_held
	_jump_was = jump_held


func set_move_x(v: float) -> void:
	move_x = clampf(v, -1.0, 1.0)


func set_move_y(v: float) -> void:
	move_y = clampf(v, -1.0, 1.0)


func clear_move() -> void:
	move_x = 0.0
	move_y = 0.0


func reset() -> void:
	clear_move()
	attack_held = false
	jump_held = false
	_attack_was = false
	_jump_was = false
	attack_just = false
	jump_just = false


func css_window_size() -> Vector2:
	var win := Vector2(DisplayServer.window_get_size())
	var scale := DisplayServer.screen_get_scale()
	if scale <= 0.0:
		scale = 1.0
	if OS.has_feature("web"):
		var w = JavaScriptBridge.eval("((window.visualViewport&&window.visualViewport.width)||window.innerWidth)||0")
		var h = JavaScriptBridge.eval("((window.visualViewport&&window.visualViewport.height)||window.innerHeight)||0")
		var fw := float(w)
		var fh := float(h)
		if fw > 1.0 and fh > 1.0:
			return Vector2(fw, fh)
	if win.x > 1.0 and win.y > 1.0:
		return win / scale
	return win


func safe_insets(view_size: Vector2) -> Vector4:
	# CSS / display safe area converted into viewport pixels. x left, y top, z right, w bottom.
	var l := 0.0
	var t := 0.0
	var r := 0.0
	var b := 0.0
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("window.huntSafeInsets ? window.huntSafeInsets() : '0,0,0,0'")
		var parts := str(raw).split(",")
		if parts.size() == 4:
			l = float(parts[0]) if parts[0].is_valid_float() else 0.0
			t = float(parts[1]) if parts[1].is_valid_float() else 0.0
			r = float(parts[2]) if parts[2].is_valid_float() else 0.0
			b = float(parts[3]) if parts[3].is_valid_float() else 0.0
		var css := css_window_size()
		if css.x > 1.0 and css.y > 1.0 and view_size.x > 1.0 and view_size.y > 1.0:
			l *= view_size.x / css.x
			r *= view_size.x / css.x
			t *= view_size.y / css.y
			b *= view_size.y / css.y
	else:
		var safe := DisplayServer.get_display_safe_area()
		var win := Vector2(DisplayServer.window_get_size())
		if win.x > 1.0 and win.y > 1.0:
			l = safe.position.x * view_size.x / win.x
			t = safe.position.y * view_size.y / win.y
			r = maxf(win.x - safe.end.x, 0.0) * view_size.x / win.x
			b = maxf(win.y - safe.end.y, 0.0) * view_size.y / win.y
	return Vector4(l, t, r, b)


func wants_touch_controls() -> bool:
	# Touch / coarse pointer, or a short landscape window. Desktop mouse stays on the keyboard.
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile"):
		return true
	if OS.has_feature("web"):
		var flag = JavaScriptBridge.eval("(function(){var coarse=false;try{coarse=window.matchMedia('(pointer: coarse)').matches;}catch(e){}var pts=(navigator.maxTouchPoints||0)>0;return (coarse||pts)?1:0;})()")
		if int(flag) == 1:
			return true
		var css := css_window_size()
		if css.x > css.y and css.y > 0.0 and css.y <= 520.0:
			return true
		return false
	# Headless reports a touchscreen even though nobody is touching it.
	if DisplayServer.get_name() == "headless":
		return false
	return DisplayServer.is_touchscreen_available()
