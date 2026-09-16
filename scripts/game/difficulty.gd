class_name Difficulty
## Every difficulty knob is a function of how many blocks have been placed.
## Tune the curve here and nowhere else.
##
## Stages (design doc §12):
##   0  Learning  – slow, wide, forgiving
##   1  Building  – faster, narrower, stability starts to matter
##   2  Pressure  – tension
##   3  Panic     – "one more block"

const STAGE_NAMES := ["Learning", "Building", "Pressure", "Panic"]
const STAGE_STARTS := [0, 15, 40, 80]  # block counts where each stage begins


static func stage(blocks: int) -> int:
	var s := 0
	for i in STAGE_STARTS.size():
		if blocks >= STAGE_STARTS[i]:
			s = i
	return s


## Horizontal speed of the moving block, px/s.
static func block_speed(blocks: int) -> float:
	return lerpf(170.0, 520.0, _ramp(blocks, 100.0))


## Width of the next block, px.
static func block_width(blocks: int) -> float:
	return lerpf(200.0, 96.0, _ramp(blocks, 90.0))


## Base rise speed of the water, px/s (the Water node adds catch-up on top).
static func water_speed(blocks: int) -> float:
	return lerpf(9.0, 55.0, _ramp(blocks, 110.0))


## 0 → 1 over the first `length` blocks, then flat.
static func _ramp(blocks: int, length: float) -> float:
	return clampf(float(blocks) / length, 0.0, 1.0)
