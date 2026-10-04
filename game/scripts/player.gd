extends Node2D

const Rules = preload("res://scripts/combat.gd")
const Stage = preload("res://scripts/stage.gd")

const SPEED := 280.0
const DEPTH_SPEED := 180.0
const JUMP_V := 560.0
const GRAVITY := 1700.0
const SPRITE_PATH := "res://sprites/player.png"

var facing := 1
var hp := 100
var max_hp := 100
var z := 0.0
var vz := 0.0
var hitstop := 0.0
var invuln := 0.0
var dead := false
var moving := false

var state := "idle"
var swing_index := 0
var swing_t := 0.0
var hit_kind := "flinch"
var connected_this := false
var want_followup := false
var chain_armed := false
var chain_next := 0
var link_left := 0.0
var hit_ids := {}
var hurt_t := 0.0
var knock_vx := 0.0
var anim := 0.0

var attack_edge := false
var jump_edge := false
var j_was := false
var jump_was := false
var tex: Texture2D

signal hp_changed(current: int, maximum: int)
signal died
signal combo_changed(text: String)


func _ready() -> void:
	add_to_group("player")
	if FileAccess.file_exists(SPRITE_PATH):
		tex = load(SPRITE_PATH)
	hp_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	_poll_edges()
	if attack_edge:
		_on_attack_pressed()
	if dead:
		queue_redraw()
		return
	if hitstop > 0.0:
		hitstop = maxf(hitstop - delta, 0.0)
		queue_redraw()
		return
	if invuln > 0.0:
		invuln = maxf(invuln - delta, 0.0)
	_apply_gravity(delta)
	if state == "attack":
		_advance_swing(delta)
	elif state == "hurt":
		_advance_hurt(delta)
	else:
		_advance_free(delta)
	_clamp()
	queue_redraw()


func hurt(amount: int, from_facing: int) -> bool:
	if dead or invuln > 0.0:
		return false
	hp = maxi(hp - amount, 0)
	invuln = 0.7
	hitstop = maxf(hitstop, Rules.HITSTOP_LIGHT)
	knock_vx = float(from_facing) * 220.0
	state = "hurt"
	hurt_t = 0.2
	_break_chain()
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		dead = true
		state = "dead"
		died.emit()
		combo_changed.emit("倒下")
	else:
		combo_changed.emit("被扑中，连段断开")
	return true


func _poll_edges() -> void:
	var j := Input.is_physical_key_pressed(KEY_J) or VInput.attack_held
	attack_edge = (j and not j_was) or VInput.attack_just
	j_was = j
	var k := (
		Input.is_physical_key_pressed(KEY_K)
		or Input.is_physical_key_pressed(KEY_SPACE)
		or VInput.jump_held
	)
	jump_edge = (k and not jump_was) or VInput.jump_just
	jump_was = k


func _on_attack_pressed() -> void:
	if dead or z > 10.0 or state == "hurt":
		return
	if state == "attack":
		if connected_this and swing_index < 2:
			if swing_t >= Rules.ACTIVE_END:
				_begin_swing(swing_index + 1)
			else:
				want_followup = true
		return
	var idx := 0
	if link_left > 0.0:
		idx = Rules.swing_index_for_press(chain_armed, chain_next, Rules.LINK_WINDOW - link_left, Rules.LINK_WINDOW)
	_begin_swing(idx)


func _begin_swing(index: int) -> void:
	state = "attack"
	swing_index = index
	swing_t = 0.0
	connected_this = false
	want_followup = false
	chain_armed = false
	chain_next = 0
	link_left = 0.0
	hit_ids.clear()
	if index == 2:
		# 上/下 = arrows or virtual pad. W/S are depth-only and do not choose throw.
		var hold_up := Input.is_physical_key_pressed(KEY_UP) or VInput.move_y < -0.2
		var hold_down := Input.is_physical_key_pressed(KEY_DOWN) or VInput.move_y > 0.2
		hit_kind = Rules.hit3_kind(hold_up, hold_down)
	else:
		hit_kind = "flinch"
	combo_changed.emit(_combo_text(index, hit_kind))


func _advance_swing(delta: float) -> void:
	var prev := swing_t
	swing_t += delta
	anim += delta * 10.0
	if swing_t >= Rules.ACTIVE_START and prev < Rules.ACTIVE_END:
		_apply_hits()
	if swing_t >= Rules.ACTIVE_END and want_followup and connected_this and swing_index < 2:
		_apply_decision(Rules.end_swing(swing_index, true, true))
		return
	if swing_t >= Rules.SWING_TIME:
		_apply_decision(Rules.end_swing(swing_index, connected_this, false))


func _apply_hits() -> void:
	var kind := hit_kind
	var dmg := Rules.damage_for(swing_index, kind)
	var stop := Rules.hitstop_for(kind)
	for node in get_tree().get_nodes_in_group("beasts"):
		var id: int = node.get_instance_id()
		if hit_ids.has(id):
			continue
		if not node.has_method("receive_hit"):
			continue
		if not _in_arc(node):
			continue
		if node.receive_hit(facing, kind, dmg, stop):
			hit_ids[id] = true
			connected_this = true
			hitstop = maxf(hitstop, stop)


func _in_arc(node: Node2D) -> bool:
	var dx := (node.global_position.x - global_position.x) * float(facing)
	var dy := absf(node.global_position.y - global_position.y)
	return dx > -16.0 and dx < 74.0 and dy < 42.0


func _apply_decision(decision: Dictionary) -> void:
	var action := str(decision["action"])
	var index := int(decision["index"])
	var did_connect := connected_this
	if action == "start":
		_begin_swing(index)
		return
	if action == "arm":
		state = "idle"
		chain_armed = true
		chain_next = index
		link_left = Rules.LINK_WINDOW
		combo_changed.emit("命中，可接第 %d 击" % (index + 1))
		return
	state = "idle"
	_break_chain()
	if did_connect:
		combo_changed.emit("连段结束")
	else:
		combo_changed.emit("落空，回到第一击")


func _break_chain() -> void:
	chain_armed = false
	chain_next = 0
	link_left = 0.0
	want_followup = false
	connected_this = false


func _advance_hurt(delta: float) -> void:
	hurt_t -= delta
	position.x += knock_vx * delta
	knock_vx = move_toward(knock_vx, 0.0, 700.0 * delta)
	anim += delta * 6.0
	if hurt_t <= 0.0:
		state = "idle"


func _advance_free(delta: float) -> void:
	if link_left > 0.0:
		link_left = maxf(link_left - delta, 0.0)
		if link_left == 0.0:
			chain_armed = false
			chain_next = 0
			combo_changed.emit("接招超时，回到第一击")
	var hx := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or VInput.move_x < -0.2:
		hx -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or VInput.move_x > 0.2:
		hx += 1.0
	var hy := 0.0
	# W/S and arrows both move depth; virtual pad uses the same axes.
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or VInput.move_y < -0.2:
		hy -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or VInput.move_y > 0.2:
		hy += 1.0
	if hx != 0.0:
		facing = -1 if hx < 0.0 else 1
	moving = hx != 0.0 or hy != 0.0
	position.x += hx * SPEED * delta
	if z <= 0.0:
		position.y += hy * DEPTH_SPEED * delta
	if jump_edge and z <= 0.0:
		vz = JUMP_V
		z = 0.1
	anim += delta * (9.0 if moving else 2.0)


func _apply_gravity(delta: float) -> void:
	if z > 0.0 or vz > 0.0:
		vz -= GRAVITY * delta
		z += vz * delta
		if z <= 0.0:
			z = 0.0
			vz = 0.0


func _clamp() -> void:
	position.x = clampf(position.x, 48.0, Stage.LEVEL_WIDTH - 48.0)
	position.y = clampf(position.y, Stage.LANE_TOP, Stage.LANE_BOTTOM)


func _combo_text(index: int, kind: String) -> String:
	var names := ["第一击", "第二击", "第三击"]
	if index < 2:
		return names[index]
	if kind == "throw_back":
		return "第三击 · 向后投"
	if kind == "throw_forward":
		return "第三击 · 向前投"
	return "第三击 · 击倒"


func _draw() -> void:
	var shadow := 1.0 - clampf(z / 220.0, 0.0, 0.45)
	draw_colored_polygon(_ellipse(18.0 * shadow, 6.0 * shadow), Color(0, 0, 0, 0.32))
	if invuln > 0.0 and sin(invuln * 46.0) > 0.0 and not dead:
		return
	var bob := 0.0
	if state != "attack" and state != "dead":
		bob = sin(anim) * 2.0
	if state == "dead":
		draw_set_transform(Vector2(0, -18), 1.2 * float(facing), Vector2(1, 1))
	else:
		draw_set_transform(Vector2(0, -z + bob), 0.0, Vector2(float(facing), 1))
	if tex:
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		draw_texture_rect(tex, Rect2(-tw * 0.5, -th, tw, th), false)
	else:
		_draw_placeholder()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_placeholder() -> void:
	var cloak := Color("#2c5a3c")
	var skin := Color("#e2be9a")
	if state == "hurt":
		cloak = Color("#6d3030")
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -8), Vector2(-14, -34), Vector2(-6, -36), Vector2(-4, -10),
	]), Color("#1d1814"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, -8), Vector2(4, -36), Vector2(12, -34), Vector2(14, -8),
	]), Color("#1d1814"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -36), Vector2(-18, -62), Vector2(-6, -70), Vector2(14, -62), Vector2(16, -34),
	]), cloak)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -58), Vector2(-14, -74), Vector2(0, -80), Vector2(12, -72), Vector2(10, -58),
	]), Color("#241c18"))
	draw_colored_polygon(_ellipse_at(Vector2(0, -86), 11, 12), skin)
	var reach := 16.0
	if state == "attack":
		var u := clampf((swing_t - 0.02) / 0.16, 0.0, 1.0)
		if swing_t > Rules.ACTIVE_END:
			u = clampf(1.0 - (swing_t - Rules.ACTIVE_END) / 0.14, 0.15, 1.0)
		reach = 20.0 + u * (48.0 if swing_index == 2 else 36.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8, -18), Vector2(72, -16), Vector2(72, 18), Vector2(-14, 16),
		]), Color(1, 1, 1, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, -50), Vector2(reach, -58), Vector2(reach + 10, -50), Vector2(12, -42),
	]), Color("#d9d3c5"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, -44), Vector2(18, -58), Vector2(22, -50), Vector2(10, -40),
	]), Color("#8a5a32"))


func _ellipse(rx: float, ry: float) -> PackedVector2Array:
	return _ellipse_at(Vector2.ZERO, rx, ry)


func _ellipse_at(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
