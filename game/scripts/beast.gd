extends Node2D

const Stage = preload("res://scripts/stage.gd")
const SPRITE_PATH := "res://sprites/beast.png"

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
	if FileAccess.file_exists(SPRITE_PATH):
		tex = load(SPRITE_PATH)


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
		var bar_y := -((tex.get_height() + 10) if tex else 86) - z
		draw_rect(Rect2(-18, bar_y, 36, 5), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(-18, bar_y, 36.0 * ratio, 5), Color("#d2c07a"))
	var bob := sin(anim) * (1.5 if state == "chase" else 0.0)
	var lay := state == "down" or state == "dead"
	if lay:
		draw_set_transform(Vector2(0, -10), 1.15 * float(facing), Vector2(1, 0.55))
	else:
		draw_set_transform(Vector2(0, -z + bob), 0.0, Vector2(float(facing), 1))
	if tex:
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		# HP bar sits above sprite
		draw_texture_rect(tex, Rect2(-tw * 0.5, -th, tw, th), false)
	else:
		_draw_placeholder()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_placeholder() -> void:
	var body := coat
	if state == "windup":
		body = body.lerp(Color("#c45a3a"), 0.45)
	elif state == "hurt":
		body = body.lerp(Color("#f2f2f2"), 0.45)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -14), Vector2(-26, -36), Vector2(-8, -48), Vector2(18, -40), Vector2(24, -16),
	]), body)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -30), Vector2(-4, -44), Vector2(14, -42), Vector2(16, -28),
	]), body.lightened(0.25))
	draw_colored_polygon(_ellipse_at(Vector2(18, -46), 12, 10), body.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([
		Vector2(20, -52), Vector2(28, -66), Vector2(32, -50),
	]), body.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([
		Vector2(24, -44), Vector2(36, -46), Vector2(30, -40),
	]), Color("#efe6cf"))
	draw_circle(Vector2(26, -48), 2.0, Color("#1a120c"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -12), Vector2(-20, -2), Vector2(-8, -2), Vector2(-8, -14),
	]), body.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, -12), Vector2(4, -2), Vector2(16, -2), Vector2(14, -14),
	]), body.darkened(0.15))


func _ellipse(rx: float, ry: float) -> PackedVector2Array:
	return _ellipse_at(Vector2.ZERO, rx, ry)


func _ellipse_at(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
