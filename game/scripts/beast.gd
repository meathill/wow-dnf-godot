extends Node2D

const Stage = preload("res://scripts/stage.gd")
# Cut boar faces left. Gameplay facing +1 is right, so the draw scale mirrors it.
# Preload (not FileAccess.file_exists) so the exported pck actually shows the sprite.
const BOAR_H := 72.0
const BOAR_TEX: Texture2D = preload("res://sprites/cut/boar.png")

@export var coat: Color = Color("#6f7d3e")

var facing := -1
var hp := 35
var max_hp := 35
var state := "chase"
var t := 0.0
var z := 0.0
var vz := 0.0
var hitstop := 0.0
var invuln := 0.0
var knock_vx := 0.0
var anim := 0.0
var tex: Texture2D

signal died


func _ready() -> void:
	add_to_group("beasts")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tex = BOAR_TEX


func receive_hit(from_facing: int, kind: String, dmg: int, stop: float) -> bool:
	if state == "dead" or state == "down" or state == "thrown" or invuln > 0.0:
		return false
	hp = maxi(hp - dmg, 0)
	hitstop = maxf(hitstop, stop)
	if hp <= 0:
		_die(from_facing)
		return true
	if kind == "knockdown":
		state = "thrown"
		knock_vx = float(from_facing) * 300.0
		vz = 240.0
		z = 1.0
	elif kind == "throw_back":
		state = "thrown"
		knock_vx = float(-from_facing) * 480.0
		vz = 380.0
		z = 1.0
	elif kind == "throw_forward":
		state = "thrown"
		knock_vx = float(from_facing) * 520.0
		vz = 320.0
		z = 1.0
	else:
		state = "hurt"
		t = 0.16
		knock_vx = float(from_facing) * 170.0
	return true


func _die(from_facing: int) -> void:
	state = "dead"
	z = 0.0
	vz = 0.0
	knock_vx = float(from_facing) * 80.0
	died.emit()


func _physics_process(delta: float) -> void:
	if state == "dead":
		queue_redraw()
		return
	if hitstop > 0.0:
		hitstop = maxf(hitstop - delta, 0.0)
		queue_redraw()
		return
	if invuln > 0.0:
		invuln = maxf(invuln - delta, 0.0)
	var player = get_tree().get_first_node_in_group("player")
	if state == "chase":
		_chase(player, delta)
	elif state == "windup":
		t -= delta
		anim += delta * 14.0
		if t <= 0.0:
			state = "bite"
			t = 0.16
			_bite(player)
	elif state == "bite":
		t -= delta
		if t <= 0.0:
			state = "chase"
	elif state == "hurt":
		t -= delta
		position.x += knock_vx * delta
		knock_vx = move_toward(knock_vx, 0.0, 500.0 * delta)
		if t <= 0.0:
			state = "chase"
	elif state == "thrown":
		position.x += knock_vx * delta
		knock_vx = move_toward(knock_vx, 0.0, 80.0 * delta)
		vz -= 1700.0 * delta
		z += vz * delta
		if z <= 0.0:
			z = 0.0
			vz = 0.0
			state = "down"
			t = 1.05
			invuln = 0.15
	elif state == "down":
		t -= delta
		if t <= 0.0:
			state = "chase"
			invuln = 0.35
	_clamp()
	anim += delta * 6.0
	queue_redraw()


func _chase(player, delta: float) -> void:
	if player == null or player.dead:
		return
	var dx: float = player.position.x - position.x
	var dy: float = player.position.y - position.y
	if absf(dx) < 56.0 and absf(dy) < 36.0 and player.z <= 24.0:
		state = "windup"
		t = 0.42
		facing = -1 if dx < 0.0 else 1
		return
	if absf(dx) > 2.0:
		facing = -1 if dx < 0.0 else 1
	var sx := 0.0 if absf(dx) < 4.0 else (1.0 if dx > 0.0 else -1.0)
	var sy := 0.0 if absf(dy) < 4.0 else (1.0 if dy > 0.0 else -1.0)
	position.x += sx * 100.0 * delta
	position.y += sy * 80.0 * delta


func _bite(player) -> void:
	if player == null or player.dead or player.z > 24.0:
		return
	if absf(player.position.x - position.x) < 64.0 and absf(player.position.y - position.y) < 42.0:
		player.hurt(10, facing)


func _clamp() -> void:
	position.x = clampf(position.x, 48.0, Stage.LEVEL_WIDTH - 48.0)
	position.y = clampf(position.y, Stage.LANE_TOP, Stage.LANE_BOTTOM)


func _draw() -> void:
	var shadow := 1.0 - clampf(z / 200.0, 0.0, 0.5)
	draw_colored_polygon(_ellipse(20.0 * shadow, 7.0 * shadow), Color(0, 0, 0, 0.3))
	if state != "dead":
		var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
		var bar_y := -BOAR_H - 10.0 - z
		draw_rect(Rect2(-18, bar_y, 36, 5), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(-18, bar_y, 36.0 * ratio, 5), Color("#d2c07a"))
	var bob := sin(anim) * (1.5 if state == "chase" else 0.0)
	var lay := state == "down" or state == "dead"
	# Art faces left; mirror so +facing looks right, matching the old hit arc.
	var flip := -1.0
	if lay:
		draw_set_transform(Vector2(0, -10), 1.15 * float(facing), Vector2(flip, 0.55))
	else:
		draw_set_transform(Vector2(0, -z + bob), 0.0, Vector2(flip * float(facing), 1))
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var s := BOAR_H / th
	var dw := tw * s
	var dh := th * s
	draw_texture_rect(tex, Rect2(-dw * 0.5, -dh, dw, dh), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ellipse(rx: float, ry: float) -> PackedVector2Array:
	return _ellipse_at(Vector2.ZERO, rx, ry)


func _ellipse_at(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
