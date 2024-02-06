@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("TurnitySocket", "Node", preload("res://addons/turnity/turn_socket.gd"), preload("res://addons/turnity/icons/turn_socket.svg"))
	add_autoload_singleton("TurnityManager", "res://addons/turnity/turn_manager.gd")
	
	
func _exit_tree():
	remove_custom_type("TurnitySocket")
	remove_autoload_singleton("TurnityManager")
