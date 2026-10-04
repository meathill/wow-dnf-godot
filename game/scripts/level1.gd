extends Node2D

const Stage = preload("res://scripts/stage.gd")
const FAR_TEX: Texture2D = preload("res://sprites/cut/bg_far.png")
const MID_TEX: Texture2D = preload("res://sprites/cut/bg_mid.png")
const LANE_TEX: Texture2D = preload("res://sprites/cut/lane_tile.jpg")
const BUSH_TEX: Texture2D = preload("res://sprites/cut/bush.png")
const ParallaxFollow := preload("res://scripts/parallax_follow.gd")
const BUSH_H := 58.0

# Fraction of the camera travel. 0 would stick to the screen. 1 matches the ground.
const FAR_SCROLL := 0.08
const MID_SCROLL := 0.25
# bg_far.png has 180px of extra sky above the original horizon line.
const FAR_SKY_PAD := 180.0
# Lane tile fills the walkable band and the grass edges above and below it.
const GROUND_TOP := 360.0
const GROUND_ROWS := 3

var player: Node2D
var cam: Camera2D
var hud: CanvasLayer
var remaining := 3
var ended := false
var far_root: Node2D
var mid_root: Node2D


func _ready() -> void:
	# Painted layers scroll in the world. None of them are parented to the camera.
	far_root = _layer("Far", -80)
	_tile_strip(far_root, FAR_TEX, FAR_SKY_PAD, 1.0, -3, 6)
	mid_root = _layer("Mid", -60)
	var mid := _sprite(MID_TEX, 1.0)
	mid.position = Vector2(0.0, 0.0)
	mid_root.add_child(mid)

	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_lane(world)
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

	var follow := Node.new()
	follow.name = "ParallaxFollow"
	follow.set_script(ParallaxFollow)
	add_child(follow)

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


func sync_parallax() -> void:
	if cam == null:
		return
	var view := get_viewport().get_visible_rect().size
	var cam_left := cam.get_screen_center_position().x - view.x * 0.5
	# World position lags the camera so the layer only travels `scroll` of the way.
	far_root.position.x = cam_left * (1.0 - FAR_SCROLL)
	mid_root.position.x = cam_left * (1.0 - MID_SCROLL)


func _layer(layer_name: String, z: int) -> Node2D:
	var node := Node2D.new()
	node.name = layer_name
	node.z_index = z
	add_child(node)
	return node


func _sprite(tex: Texture2D, scale_xy: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2(scale_xy, scale_xy)
	return sprite


func _tile_strip(parent: Node2D, tex: Texture2D, y: float, scale_xy: float, i0: int, i1: int) -> void:
	var step := tex.get_width() * scale_xy
	for i in range(i0, i1):
		var sprite := _sprite(tex, scale_xy)
		sprite.position = Vector2(step * float(i), -y)
		parent.add_child(sprite)


func _lane(world: Node2D) -> void:
	var tex := _seamless_lane(LANE_TEX.get_image())
	var ground_h := Stage.VIEW_H - GROUND_TOP
	var scale := ground_h / float(tex.get_height())
	var step := float(tex.get_width()) * scale
	var x0 := -step * 3.0
	var x1 := Stage.LEVEL_WIDTH + step * 4.0
	var guard := 0
	var x := x0
	while x < x1 and guard < 48:
		for row in GROUND_ROWS:
			var sprite := _sprite(tex, scale)
			sprite.name = "Lane"
			sprite.z_index = -20
			sprite.position = Vector2(x, GROUND_TOP + ground_h * float(row))
			world.add_child(sprite)
		x += step
		guard += 1


func _seamless_lane(src: Image) -> Texture2D:
	# Fade the right edge into the left edge so a horizontal repeat has no seam.
	var img: Image = src.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var blend: int = mini(96, int(w / 5))
	for y in h:
		for d in blend:
			var t: float = float(blend - d) / float(blend)
			t = t * t * (3.0 - 2.0 * t)
			var x: int = w - 1 - d
			var here: Color = img.get_pixel(x, y)
			var edge: Color = img.get_pixel(d, y)
			img.set_pixel(x, y, here.lerp(edge, t))
	# Soft top so the grass edge sits on the hills instead of a hard cut.
	var fade: int = mini(72, h)
	for y in fade:
		var a: float = float(y) / float(fade - 1)
		a = a * a * (3.0 - 2.0 * a)
		for x in w:
			var px: Color = img.get_pixel(x, y)
			px.a = a
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


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
