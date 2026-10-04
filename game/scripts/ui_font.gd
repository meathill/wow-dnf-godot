extends RefCounted

const FONT_PATH := "res://fonts/NotoSansSC-Regular.ttf"

static var _cached: Font


static func get_font() -> Font:
	if _cached != null:
		return _cached
	if ResourceLoader.exists(FONT_PATH):
		_cached = load(FONT_PATH) as Font
	if _cached == null:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray(["Noto Sans CJK SC", "Noto Sans SC", "Sans"])
		_cached = fallback
	return _cached
