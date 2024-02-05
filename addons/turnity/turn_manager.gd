extends Node

signal turnity_socket_connected(socket: TurnitySocket)
signal turnity_socket_disconnected(socket: TurnitySocket)
signal connected_turnity_sockets(sockets: Array[TurnitySocket])
signal disconnected_turnity_sockets(sockets: Array[TurnitySocket])
signal turn_changed(previous_socket: TurnitySocket, next_socket: TurnitySocket)
signal activated_turn(current_socket: TurnitySocket)
signal ended_turn(last_socket: TurnitySocket)
signal last_turn_reached
signal finished

enum MODE {
	SERIAL, ## The turns comes one after another
	DYNAMIC_QUEUE, ## The queue changes every turn based on the custom sort rule applied
}

var current_turnity_sockets: Array[TurnitySocket] = []
var current_turn_socket: TurnitySocket
var current_mode: MODE = MODE.SERIAL

var sort_rule: Callable = func(a: TurnitySocket, b: TurnitySocket): return a.id > b.id
var turn_duration := 0
var turns_passed := 0
var max_turns := 0
var automatic_move_on_to_the_next_turn := false

func _enter_tree():
	add_to_group("turnity-manager")


func _ready():
	finished.connect(on_finished)


func start(root_node = null):
	if is_node_ready():
		reset_active_sockets()
		current_turnity_sockets = get_active_sockets(root_node)
		apply_sort_rule(current_turnity_sockets)
		connect_turnity_sockets()
		deactivate_sockets(current_turnity_sockets)	 ## We deactivate all the sockets to only make active the first one on the initialization
		set_turn_duration_on_sockets()
		
		current_turn_socket.active_turn.emit()
		activated_turn.emit(current_turn_socket)
	else:
		push_error("Turnity: The TurnityManager is not ready or appended into the scene tree, the turn system cannot be initialized")


### CUSTOM BEHAVIOUR FUNCTIONS ###
func set_mode(mode: MODE) -> TurnityManager:
	current_mode = mode
	
	return self


func set_serial_mode() -> TurnityManager:
	current_mode = MODE.SERIAL
	
	return self


func set_dynamic_queue_mode() -> TurnityManager:
	current_mode = MODE.DYNAMIC_QUEUE
	
	return self


func automatically_move_on_to_the_next_turn(enabled: bool = false):
	automatic_move_on_to_the_next_turn = enabled
	
	
func set_limited_turns(turns: int) -> TurnityManager:
	max_turns = turns
	
	return self


func set_turn_duration(time: int = 0) -> TurnityManager:
	turn_duration = abs(time)
	
	return self


func set_turn_duration_on_sockets() -> void:
	if turn_duration > 0:
		for socket in current_turnity_sockets:
			if socket.turn_duration == 0: ## The local turn duration value of each socket is prioritized
				socket.change_turn_duration(turn_duration)


func set_sort_rule(callable: Callable) -> TurnityManager:
	sort_rule = callable
	
	return self
	
	
func apply_sort_rule(sockets: Array[TurnitySocket] = current_turnity_sockets):
	sockets.sort_custom(sort_rule)
	

### SOCKET CONNECTION & DISCONNECTION FUNCTIONS
func deactivate_sockets(sockets: Array[TurnitySocket]) -> void:
	for socket in current_turnity_sockets:
			socket.active = false


func all_sockets_are_disabled(sockets: Array[TurnitySocket]) -> bool:
	return sockets.filter(func(socket: TurnitySocket): return socket.is_disabled()).size() == sockets.size()


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
			
			
func next_turn() -> void:
	var next_socket: TurnitySocket
	
	if all_sockets_are_disabled(current_turnity_sockets) or turns_passed >= max_turns:
		finished.emit()
		return
	
	if not current_turnity_sockets.is_empty():
		turns_passed += 1
		
		match(current_mode):
				MODE.SERIAL:
					var index = current_turnity_sockets.find(current_turn_socket)
					next_socket = current_turnity_sockets.front() if index + 1 >= current_turnity_sockets.size() else current_turnity_sockets[index + 1]				
				MODE.DYNAMIC_QUEUE:
					## TODO
					pass
		
		if turns_passed + 1 == max_turns:
			last_turn_reached.emit()
		
		turn_changed.emit(current_turn_socket, next_socket)
		next_socket.active_turn.emit()


func reset_active_sockets() -> void:
	turns_passed = 0
	sort_rule = func(a: TurnitySocket, b: TurnitySocket): return a.id > b.id
	
	disconnect_turnity_sockets()
	current_turnity_sockets.clear()
	current_turn_socket = null


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
	
	if automatic_move_on_to_the_next_turn:
		next_turn()


func on_finished():
	reset_active_sockets()
	turn_duration = 0
	max_turns = 0

