extends Node
signal tick(step: float)

const TICK_RATE := 10.0
const TICK_STEP := 1.0 / TICK_RATE

var running: bool = true
var _accum := 0.0

func _ready() -> void:
	set_process(true)      # IMPORTANT: Node._process is off by default

func _process(delta: float) -> void:
	if !running: return
	_accum += delta
	while _accum >= TICK_STEP:
		_accum -= TICK_STEP
		tick.emit(TICK_STEP)
	# anyone can listen to this
