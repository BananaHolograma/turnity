<p align="center">
	<img width="256px" src="https://github.com/bananaholograma/turnity/blob/main/icon.png" alt="bananaholograma turnity logo" />
	<h1 align="center">Turnity</h1>
	
[![LastCommit](https://img.shields.io/github/last-commit/bananaholograma/turnity?cacheSeconds=600)](https://github.com/bananaholograma/turnity/commits)
[![Stars](https://img.shields.io/github/stars/bananaholograma/turnity)](https://github.com/bananaholograma/turnity/stargazers)
[![Total downloads](https://img.shields.io/github/downloads/bananaholograma/turnity/total.svg?label=Downloads&logo=github&cacheSeconds=600)](https://github.com/bananaholograma/turnity/releases)
[![License](https://img.shields.io/github/license/bananaholograma/turnity?cacheSeconds=2592000)](https://github.com/bananaholograma/turnity/blob/main/LICENSE.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat&logo=github)](https://github.com/bananaholograma/turnity/pulls)
[![Kofi](https://badgen.net/badge/icon/kofi?icon=kofi&label)](https://ko-fi.com/bananaholograma)
</p>

[![es](https://img.shields.io/badge/lang-es-yellow.svg)](https://github.com/bananaholograma/turnity/blob/main/locale/README.es-ES.md)

- - -

Your go-to plugin for streamlined turn management in Godot. Elevate your game's experience with efficient turn-based mechanics. Craft dynamic battles and engaging scenarios effortlessly.

- **Flexible Turn Modes**: Choose between serial mode (turns one after another) and dynamic queue mode (customizable turn order based on a sort rule every turn).
- **Configurable Parameters**: Adjust turn duration, set a maximum number of turns, enable automatic progression to the next turn and much more.
- **Dynamic Sorting**: Define custom sorting rules for turn order.
- **Easy Integration**: Seamlessly integrate Turnity with your Godot project using just 2 Nodes, connecting and disconnecting TurnitySockets effortlessly.

- - -

- [Requirements](#requirements)
- [✨Installation](#installation)
	- [Automatic (Recommended)](#automatic-recommended)
	- [Manual](#manual)
- [Getting started](#getting-started)
	- [Initializing a new turn system](#initializing-a-new-turn-system)
	- [Manually move to the next turn](#manually-move-to-the-next-turn)
		- [Available accessors and signals](#available-accessors-and-signals)
		- [Available methods](#available-methods)
- [How to add a TurnitySocket](#how-to-add-a-turnitysocket)
	- [Via editor](#via-editor)
	- [Via script](#via-script)
- [✌️You are welcome to](#️you-are-welcome-to)
- [🤝Contribution guidelines](#contribution-guidelines)
- [📇Contact us](#contact-us)


# Requirements
📢 We don't currently give support to Godot 3+ as we focus on future stable versions from version 4 onwards
* Godot 4+

# ✨Installation
## Automatic (Recommended)
You can download this plugin from the official [Godot asset library](https://godotengine.org/asset-library/asset/[PLUGIN-ID]) using the AssetLib tab in your godot editor. Once installed, you're ready to get started
##  Manual 
To manually install the plugin, create an **"addons"** folder at the root of your Godot project and then download the contents from the **"addons"** folder of this repository

# Getting started
This plugin allows you to configure a turn based system by applying nodes that we will call `TurnitySocket`. When you attach this node in your scene and link an actor to it, i.e. the node it belongs to (player, enemy, etc.) understands that it must be added to the turn queue when it's initialized.

## Initializing a new turn system
Imagine that your videogame triggers an event to start a battle, it is at this moment when we want to initialize the turn system with the members of that battle.

**You can pass it as a parameter the `root node` where you want it to get the sockets recursively. If no value is passed it uses `get_tree()` by default and collects all sockets by their group name *(defined internally by the plugin)*.

***Each time the function `start()` is invoked, it restarts all the internal parameters, it is good to keep this in mind in order not to restart the shift system unintentionally.***

The `TurnityManager` singleton allows you setup this configuration using chain syntax as we show in the next example:

```python
extends Node
##...

func _init_battle():
	TurnityManager.set_serial_mode()\
		.set_limited_turns(5)\
		.set_turn_duration(30)\
		.automatically_move_on_to_the_next_turn(false)
		.set_sort_rule(your_custom_sort_function)
		.start(self)


func your_custom_sort_function(socket_a: TurnitySocket, socket_b: TurnitySocket) -> void:
		## Write your logic here, it can be anything you need to sort the turn queue
		socket_a.actor.agility > socket_b.actor.agility
##...

```
**You can configure:**
- The number of turns this new "battle" will endure, once the last turn is consumed the `finished signal` is emitted
- The turn duration in seconds, an automatic timer is managed by you to end the turn when the counter reaches zero.
- The next turn can be automatic or not, it means that if for example the turn duration reachs zero it will pass to the next TurnitySocket
- The sort callback applied to define the order of the turn queue, apply your own ordering logic.

## Manually move to the next turn
The automatic step really only applies when the `turn_duration` is greater than zero, the rest must be applied manually. This allows you to apply the necessary logic of your game before passing the turn.

This method automatically determines according to the selected mode which is the next turn:
```python
TurnityManager.next_turn()

## And then access the new updated socket that represents the new turn
TurnityManager.current_turn_socket
```

### Available accessors and signals
You can collect quite a lot of important information from this node:

 ```python
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
 ```

### Available methods
```python
### TURN ACTIVE ACTION ###
func start(root_node = null):
func next_turn() -> void:


### TURN RULES ###
func set_mode(mode: MODE) -> TurnityManager
func set_serial_mode() -> TurnityManager:
func set_dynamic_queue_mode() -> void
func automatically_move_on_to_the_next_turn(enabled: bool = false) -> void
func set_limited_turns(turns: int) -> TurnityManager
func set_turn_duration(time: int = 0) -> TurnityManager
func set_sort_rule(callable: Callable) -> TurnityManager:
func apply_sort_rule(sockets: Array[TurnitySocket] = current_turnity_sockets):
```

# How to add a TurnitySocket
You can choose the manual path and add it as a node in the editor or initialize it through a script:

## Via editor

- ![turnity-socket-search](images/turnity-socket-search.png)

- ![turnity-socket-node](images/turnity-socket.png)


## Via script
```python
var socket = TurnitySocket.new()
socket.actor = <your_node>
add_child(socket)
```

The `TurnitySocket` does not need to be a child of the node to which we want to attach. For this we have an exportable variable called `actor` in which we can assign the node that we want independently of the hierarchy.



# ✌️You are welcome to
- [Give feedback](https://github.com/bananaholograma/turnity/pulls)
- [Suggest improvements](https://github.com/bananaholograma/turnity/issues/new?assignees=BananaHolograma&labels=enhancement&template=feature_request.md&title=)
- [Bug report](https://github.com/bananaholograma/turnity/issues/new?assignees=BananaHolograma&labels=bug%2C+task&template=bug_report.md&title=)

This plugin is available for free.

If you're grateful for what we're doing, please consider a donation. Developing plugins requires massive amount of time and knowledge, especially when it comes to Godot. Even $1 is highly appreciated and shows that you care. Thank you!

- - -
# 🤝Contribution guidelines
**Thank you for your interest in this plugin!**

To ensure a smooth and collaborative contribution process, please review our [contribution guidelines](https://github.com/bananaholograma/turnity/blob/main/CONTRIBUTING.md) before getting started. These guidelines outline the standards and expectations we uphold in this project.

**📓Code of Conduct:** We strictly adhere to the [Godot code of conduct](https://godotengine.org/code-of-conduct/) in this project. As a contributor, it is important to respect and follow this code to maintain a positive and inclusive community.

- - -

# 📇Contact us
If you have built a project, demo, script or example with this plugin let us know and we can publish it here in the repository to help us to improve and to know that what we do is useful.
