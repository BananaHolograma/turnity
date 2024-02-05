class_name TurnitySocket extends Node

signal active_turn
signal ended_turn
signal changed_turn_duration(old_duration: int, new_duration: int)
signal reset_current_timer
signal blocked_n_turns(turns: int, total_turns: int)
signal blocked_turn_consumed(remaining_turns: int)
signal skipped

## The linked actor in the turn system
@export var actor: Node
## The turn duration for this socket, leave it to zero to make it infinite
@export var turn_duration := 0

var timer: Timer
var active := false
var blocked_turns := 0


func _enter_tree():
	add_to_group("turnity-socket")
	
	if not actor:
		actor = get_parent()
		if actor == null:
			push_error("Turnity: The TurnitySocket needs a valid actor linked, cannot stand alone")


func _ready():
	_create_timer()
	
	active_turn.connect(on_active_turn)
	ended_turn.connect(on_ended_turn)
	

func _create_timer():
	timer = Timer.new()
	timer.name = "TurnitySocketTimer"
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.wait_time = max(0.05, turn_duration)
	timer.one_shot = true
	timer.autostart = false

	add_child(timer)
	timer.timeout.connect(on_timeout)


func change_turn_duration(new_duration: int):
	if timer.is_inside_tree():
		changed_turn_duration.emit(timer.wait_time, new_duration)
		timer.stop()
		timer.wait_time = max(0.05, new_duration)


func reset_active_timer():
	if timer.is_inside_tree() and timer.time_left > 0:
		timer.start()
		reset_current_timer.emit()
		

func block_a_number_of_turns(turns: int):
	blocked_turns += turns
	blocked_n_turns.emit(turns, blocked_turns)


func is_blocked() -> bool:
	return blocked_turns > 0


func skip():
	if active:
		ended_turn.emit()
		skipped.emit()

### SIGNAL CALLBACKS ###
func on_active_turn():
	active = true
	
	if blocked_turns > 0:
		blocked_turns -= 1
		blocked_turn_consumed.emit(blocked_turns)
		ended_turn.emit()
		return
		
	if timer and turn_duration > 0 and not active:
		timer.start()
	

func on_ended_turn():
	active = false


func on_timeout():
	ended_turn.emit()

