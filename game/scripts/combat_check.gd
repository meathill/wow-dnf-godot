extends SceneTree

const Rules = preload("res://scripts/combat.gd")

var failed := 0


func _init() -> void:
	_expect(Rules.swing_index_for_press(false, 1, 0.0, Rules.LINK_WINDOW) == 0, "unarmed stays hit 1")
	_expect(Rules.swing_index_for_press(true, 0, 0.0, Rules.LINK_WINDOW) == 0, "armed next 0 is not a link")
	_expect(Rules.swing_index_for_press(true, 1, 0.0, Rules.LINK_WINDOW) == 1, "armed hit 2 in window")
	_expect(Rules.swing_index_for_press(true, 2, Rules.LINK_WINDOW, Rules.LINK_WINDOW) == 2, "boundary still links")
	_expect(Rules.swing_index_for_press(true, 2, Rules.LINK_WINDOW + 0.01, Rules.LINK_WINDOW) == 0, "expired window resets")

	_expect(Rules.end_swing(0, true, true)["action"] == "start" and Rules.end_swing(0, true, true)["index"] == 1, "connect + press links to hit 2")
	_expect(Rules.end_swing(1, true, true)["index"] == 2, "second connect links to hit 3")
	_expect(Rules.end_swing(0, true, false)["action"] == "arm" and Rules.end_swing(0, true, false)["index"] == 1, "connect without press arms")
	_expect(Rules.end_swing(1, false, false)["action"] == "idle", "whiff resets")
	_expect(Rules.end_swing(1, false, true)["action"] == "idle", "press without connect does not link")
	_expect(Rules.end_swing(2, true, true)["action"] == "idle", "hit 3 ends the chain")
	_expect(Rules.end_swing(2, false, false)["action"] == "idle", "whiffed hit 3 resets")

	_expect(Rules.hit3_kind(true, true) == "throw_back", "up wins over down")
	_expect(Rules.hit3_kind(true, false) == "throw_back", "up throws behind")
	_expect(Rules.hit3_kind(false, true) == "throw_forward", "down throws forward")
	_expect(Rules.hit3_kind(false, false) == "knockdown", "neutral knockdown")

	_expect(is_equal_approx(Rules.hitstop_for("flinch"), 0.085), "light hitstop")
	_expect(is_equal_approx(Rules.hitstop_for("knockdown"), 0.150), "knockdown hitstop")
	_expect(is_equal_approx(Rules.hitstop_for("throw_back"), 0.130), "throw back hitstop")
	_expect(is_equal_approx(Rules.hitstop_for("throw_forward"), 0.130), "throw forward hitstop")
	_expect(Rules.damage_for(0, "flinch") == 8, "hit 1 damage")
	_expect(Rules.damage_for(1, "flinch") == 11, "hit 2 damage")
	_expect(Rules.damage_for(2, "knockdown") == 16, "knockdown damage")
	_expect(Rules.damage_for(2, "throw_forward") == 14, "throw damage")

	if failed == 0:
		print("COMBAT_CHECK_OK")
		quit(0)
	else:
		print("COMBAT_CHECK_FAIL %d" % failed)
		quit(1)


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		print("FAIL ", message)
