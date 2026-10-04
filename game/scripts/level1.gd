extends Node2D

const Stage = preload("res://scripts/stage.gd")

var player: Node2D
var cam: Camera2D
var hud: CanvasLayer
var remaining := 3
var ended := false
var backdrop: Sprite2D


func _ready() -> void:
	var has_bg := FileAccess.file_exists("res://sprites/bg_hunt.png")
	if not has_bg:
		_build_scenery()
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_bushes(world)

	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector2(180, 560)
	world.add_child(player)

	var coats: Array[Color] = [Color("#6f7d3e"), Color("#4e6236"), Color("#7d6a3a")]
	var spots: Array[Vector2] = [Vector2(700, 500), Vector2(1120, 600), Vector2(1580, 530)]
	for i in spots.size():
		var beast := preload("res://scenes/beast.tscn").instantiate()
		beast.position = spots[i]
		beast.coat = coats[i]
		world.add_child(beast)
		beast.died.connect(_on_beast_died)

	cam = Camera2D.new()
	cam.position = Vector2(Stage.VIEW_W * 0.5, Stage.VIEW_H * 0.5)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(Stage.LEVEL_WIDTH)
	cam.limit_bottom = int(Stage.VIEW_H)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	cam.make_current()
	if has_bg:
		backdrop = Sprite2D.new()
		backdrop.name = "Backdrop"
		backdrop.texture = load("res://sprites/bg_hunt.png")
		backdrop.centered = true
		backdrop.z_index = -40
		backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cam.add_child(backdrop)
		_fit_backdrop()

	hud = preload("res://scenes/hud.tscn").instantiate()
	add_child(hud)
	player.hp_changed.connect(hud.set_hp)
	player.combo_changed.connect(hud.set_combo)
	player.died.connect(_on_player_died)
	hud.set_hp(player.hp, player.max_hp)
	hud.set_remaining(remaining)


func _process(_delta: float) -> void:
	if player:
		cam.position = Vector2(player.position.x, Stage.VIEW_H * 0.5)
	_fit_backdrop()


func _fit_backdrop() -> void:
	if backdrop == null or backdrop.texture == null:
		return
	var view := get_viewport().get_visible_rect().size
	var tex_size := backdrop.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var cover := maxf(view.x / tex_size.x, view.y / tex_size.y)
	backdrop.scale = Vector2(cover, cover)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_R or event.keycode == KEY_R):
		get_tree().reload_current_scene()


func _on_beast_died() -> void:
	remaining = maxi(remaining - 1, 0)
	if hud:
		hud.set_remaining(remaining)
	if remaining == 0 and not ended:
		ended = true
		hud.show_result("猎归\n荆丛里的野兽已经清掉。猎户村还在前头。\n按 R 再走一趟。")


func _on_player_died() -> void:
	if ended:
		return
	ended = true
	hud.show_result("林狩倒下了\n按 R 重开")


func _build_scenery() -> void:
	var scenery := Node2D.new()
	scenery.name = "Scenery"
	scenery.z_index = -10
	add_child(scenery)
	var width := Stage.LEVEL_WIDTH
	_poly(scenery, PackedVector2Array([
		Vector2(0, 0), Vector2(width, 0), Vector2(width, 430), Vector2(0, 430),
	]), Color("#8eabbf"))
	_hill(scenery, width, Color("#6d8b78"), 300.0, 70.0, 90.0)
	_hill(scenery, width, Color("#3f624c"), 390.0, 48.0, 70.0)
	_poly(scenery, PackedVector2Array([
		Vector2(0, 430), Vector2(width, 430), Vector2(width, Stage.VIEW_H), Vector2(0, Stage.VIEW_H),
	]), Color("#6a5338"))
	_poly(scenery, PackedVector2Array([
		Vector2(0, Stage.LANE_TOP), Vector2(width, Stage.LANE_TOP),
		Vector2(width, Stage.LANE_BOTTOM), Vector2(0, Stage.LANE_BOTTOM),
	]), Color("#7d6244"))
	_poly(scenery, PackedVector2Array([
		Vector2(0, Stage.LANE_TOP), Vector2(width, Stage.LANE_TOP),
		Vector2(width, Stage.LANE_TOP + 6), Vector2(0, Stage.LANE_TOP + 6),
	]), Color("#3e4a38"))
	_poly(scenery, PackedVector2Array([
		Vector2(0, Stage.LANE_BOTTOM), Vector2(width, Stage.LANE_BOTTOM),
		Vector2(width, Stage.LANE_BOTTOM + 8), Vector2(0, Stage.LANE_BOTTOM + 8),
	]), Color("#3a2c22"))


func _bushes(world: Node2D) -> void:
	var spots := [
		Vector2(320, 470), Vector2(540, 640), Vector2(860, 460),
		Vector2(1280, 648), Vector2(1500, 470), Vector2(1900, 620), Vector2(2050, 490),
	]
	for i in spots.size():
		var bush := Polygon2D.new()
		bush.position = spots[i]
		bush.color = Color("#2f4a34") if i % 2 == 0 else Color("#3d5a32")
		bush.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(-26, -8), Vector2(-16, -42), Vector2(0, -56), Vector2(18, -40), Vector2(28, -6),
		])
		world.add_child(bush)


func _hill(parent: Node2D, width: float, color: Color, base_y: float, amp: float, step: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, base_y + 30))
	var x := 0.0
	var i := 0
	while x <= width:
		var y := base_y - amp * (0.45 + 0.55 * absf(sin(float(i) * 1.7)))
		pts.append(Vector2(x, y))
		x += step
		i += 1
	pts.append(Vector2(width, base_y + 40))
	_poly(parent, pts, color)


func _poly(parent: Node, pts: PackedVector2Array, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	parent.add_child(poly)
