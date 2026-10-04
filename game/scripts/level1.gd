extends Node2D

const Stage = preload("res://scripts/stage.gd")
const BACKDROP_TEX: Texture2D = preload("res://sprites/cut/bg_hunt.jpg")
const BUSH_TEX: Texture2D = preload("res://sprites/cut/bush.png")
const BUSH_H := 58.0

var player: Node2D
var cam: Camera2D
var hud: CanvasLayer
var remaining := 3
var ended := false
var backdrop: Sprite2D


func _ready() -> void:
	# Painted backdrop is preloaded. Do not draw the flat sky / hill / lane polygons on top.
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
	backdrop = Sprite2D.new()
	backdrop.name = "Backdrop"
	backdrop.texture = BACKDROP_TEX
	backdrop.centered = true
	backdrop.z_index = -40
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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


func _bushes(world: Node2D) -> void:
	var spots := [
		Vector2(320, 470), Vector2(540, 640), Vector2(860, 460),
		Vector2(1280, 648), Vector2(1500, 470), Vector2(1900, 620), Vector2(2050, 490),
	]
	var scales: Array[float] = [1.0, 0.86, 1.08, 0.94, 1.04, 0.9, 1.0]
	var tex_w := float(BUSH_TEX.get_width())
	var tex_h := float(BUSH_TEX.get_height())
	for i in spots.size():
		var bush := Sprite2D.new()
		bush.name = "Bush%d" % i
		bush.texture = BUSH_TEX
		bush.centered = false
		bush.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# Base of the cluster sits on the old polygon origin so y-sort matches the lane.
		bush.offset = Vector2(-tex_w * 0.5, -tex_h)
		var s := (BUSH_H / tex_h) * scales[i]
		bush.scale = Vector2(s, s)
		bush.position = spots[i]
		world.add_child(bush)
