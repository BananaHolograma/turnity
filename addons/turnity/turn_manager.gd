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

var current_turnity_sockets: Array[TurnitySocket] = []
var current_turn_socket: TurnitySocket
var current_mode: MODE = MODE.SERIAL

var serial_queue: Array[TurnitySocket] = []
var dynamic_queue: Array[TurnitySocket] = []
var static_queue: Array[TurnitySocket] = []

var sort_rule: Callable = func(a, b): return a > b
var turn_duration := 0
var turns_passed := 0


func _enter_tree():
	add_to_group("turnity-manager")


func start(root_node = null):
	if is_node_ready():
		reset_active_sockets()
		current_turnity_sockets = get_active_sockets(root_node)
		connect_turnity_sockets()
		
		match(current_mode):
			MODE.SERIAL:
				pass
			MODE.STATIC_QUEUE:
				pass
			MODE.DYNAMIC_QUEUE:
				pass
	else:
		push_error("Turnity: The TurnityManager is not ready or appended into the scene tree, the turn system cannot be initialized")

### CUSTOM BEHAVIOUR FUNCTIONS ###
func set_mode(mode: MODE) -> TurnityManager:
	current_mode = mode
	
	return self


func set_turn_duration(time: int = 0) -> TurnityManager:
	turn_duration = abs(time)
	
	return self


func set_sort_rule(callable: Callable) -> TurnityManager:
	sort_rule = callable
	
	return self
	
	
func apply_sort_rule():
	current_turnity_sockets.sort_custom(sort_rule)
	

### SOCKET CONNECTION & DISCONNECTION FUNCTIONS
func get_active_sockets(root_node = null) -> Array[TurnitySocket]:
	var sockets: Array[TurnitySocket] = []
	var nodes = []
	
	if root_node == null:
		nodes = get_tree().get_nodes_in_group("turnity-socket").filter(func(node): return node is TurnitySocket)
		## We need to manual append the nodes to a new array to make the static typing works on arrays for the compiler
		for socket in nodes:
			sockets.append(socket)
	else:
		read_sockets_from_node(root_node, sockets)
	
	return sockets


func read_sockets_from_node(node: Node, sockets: Array):
	var childrens = node.get_children(true)
	
	for child in childrens:
		if child is TurnitySocket:
			sockets.append(child)
		else:
			read_sockets_from_node(child, sockets)


func reset_active_sockets() -> void:
	turns_passed = 0
	turn_duration = 0
	sort_rule = func(a, b): return a > b
	
	disconnect_turnity_sockets()
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
