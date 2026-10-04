extends RefCounted

# Ground chain rules for level 1. No global time scale lives here.

const SWING_TIME := 0.32
const ACTIVE_START := 0.08
const ACTIVE_END := 0.18
const LINK_WINDOW := 0.28
const HITSTOP_LIGHT := 0.085
const HITSTOP_KNOCKDOWN := 0.150
const HITSTOP_THROW := 0.130
const COMBO_DAMAGE: Array[int] = [8, 11, 16]
const THROW_DAMAGE := 14


static func swing_index_for_press(armed: bool, next_index: int, elapsed: float, window: float) -> int:
	if armed and next_index > 0 and elapsed <= window:
		return next_index
	return 0


static func end_swing(hit_index: int, connected: bool, want_followup: bool) -> Dictionary:
	# Hit 2 and hit 3 only if the previous hit connected and a follow-up was asked for.
	if want_followup and connected and hit_index < 2:
		return {"action": "start", "index": hit_index + 1}
	if connected and hit_index < 2:
		return {"action": "arm", "index": hit_index + 1}
	return {"action": "idle", "index": 0}


static func hit3_kind(hold_up: bool, hold_down: bool) -> String:
	if hold_up:
		return "throw_back"
	if hold_down:
		return "throw_forward"
	return "knockdown"


static func hitstop_for(kind: String) -> float:
	if kind == "knockdown":
		return HITSTOP_KNOCKDOWN
	if kind == "throw_back" or kind == "throw_forward":
		return HITSTOP_THROW
	return HITSTOP_LIGHT


static func damage_for(hit_index: int, kind: String) -> int:
	if kind == "throw_back" or kind == "throw_forward":
		return THROW_DAMAGE
	return COMBO_DAMAGE[clampi(hit_index, 0, 2)]
