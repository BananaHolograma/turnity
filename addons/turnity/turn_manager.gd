extends Node

signal turnity_socket_connected(socket: TurnitySocket)
signal turnity_socket_disconnected(socket: TurnitySocket)
signal connected_turnity_sockets(sockets: Array[TurnitySocket])
signal disconnected_turnity_sockets(sockets: Array[TurnitySocket])
signal turn_changed(next_socket: TurnitySocket)
signal activated_turn(current_socket: TurnitySocket)
signal ended_turn(last_socket: TurnitySocket)

enum MODE {
	SERIAL, ## The turns comes one after another
	DYNAMIC_QUEUE, ## The queue changes every turn based on the custom sort rule applied
	STATIC_QUEUE ## The queue is initialized and never changes again the order of the turns
}

@onready var current_turnity_sockets: Array[TurnitySocket] = get_active_sockets()

var current_mode: MODE = MODE.SERIAL:
	set(value):
		if value != current_mode:
			clean_active_sockets()
			
		current_mode = value

var current_turn_socket: TurnitySocket

var serial_queue: Array[TurnitySocket] = []
var dynamic_queue: Array[TurnitySocket] = []
var static_queue: Array[TurnitySocket] = []

var turns_passed := 0

func _enter_tree():
	add_to_group("turnity-manager")


### CUSTOM BEHAVIOUR FUNCTIONS ###
func set_mode(mode: MODE):
		current_mode = mode
		
		
func apply_sort_rule(callable: Callable):
	current_turnity_sockets.sort_custom(callable)


### SOCKET CONNECTION & DISCONNECTION FUNCTIONS
func get_active_sockets() -> Array[TurnitySocket]:
	var sockets: Array[TurnitySocket] = []
	var nodes = get_tree().get_nodes_in_group("turnity-socket").filter(func(node): return node is TurnitySocket)
	
	## We need to manual append the nodes to a new array to make the static typing works on arrays for the compiler
	for socket in nodes:
		sockets.append(socket)
		
	return sockets


func clean_active_sockets() -> void:
	turns_passed = 0
	current_turnity_sockets.clear()
	serial_queue.clear()
	static_queue.clear()
	dynamic_queue.clear()


func connect_turnity_sockets() -> void:
	for socket: TurnitySocket in current_turnity_sockets:
		_connect_socket(socket)
	
	if not current_turnity_sockets.is_empty():
		connected_turnity_sockets.emit(current_turnity_sockets)


func disconnect_turnity_sockets() -> void:
	if not current_turnity_sockets.is_empty():
		disconnected_turnity_sockets.emit(current_turnity_sockets)
		 
	for socket: TurnitySocket in current_turnity_sockets:
		_disconnect_socket(socket)


func _connect_socket(socket: TurnitySocket):
	var connected_signal_emitted = false
	
	if not socket.active_turn.is_connected(on_socket_active_turn):
		socket.active_turn.connect(on_socket_active_turn.bind(socket))
		turnity_socket_connected.emit(socket)
		connected_signal_emitted = true
		
	if not socket.ended_turn.is_connected(on_socket_ended_turn):
		socket.ended_turn.connect(on_socket_ended_turn.bind(socket))
		
		if not connected_signal_emitted:
			turnity_socket_connected.emit(socket)
		
		
func _disconnect_socket(socket: TurnitySocket):
	var disconnected_signal_emitted = false
	
	if socket.active_turn.is_connected(on_socket_active_turn):
		socket.active_turn.disconnect(on_socket_active_turn.bind(socket))
		turnity_socket_disconnected.emit(socket)
		disconnected_signal_emitted = true
		
	if socket.ended_turn.is_connected(on_socket_ended_turn):
		socket.ended_turn.disconnect(on_socket_ended_turn.bind(socket))
		
		if not disconnected_signal_emitted:
			turnity_socket_disconnected.emit(socket)
		
		
	
### SIGNAL CALLBACKS ###
func on_socket_active_turn(socket: TurnitySocket):
	activated_turn.emit(socket)
	current_turn_socket = socket


func on_socket_ended_turn(socket: TurnitySocket):
	ended_turn.emit(socket)
	turns_passed += 1
