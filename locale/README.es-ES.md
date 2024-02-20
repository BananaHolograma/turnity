<p align="center">
	<img width="256px" src="https://github.com/bananaholograma/turnity/blob/main/icon.png" alt="turnity logo" />
	<h1 align="center">turnity</h1>
	
[![LastCommit](https://img.shields.io/github/last-commit/bananaholograma/turnity?cacheSeconds=600)](https://github.com/bananaholograma/turnity/commits)
[![Stars](https://img.shields.io/github/stars/bananaholograma/turnity)](https://github.com/bananaholograma/turnity/stargazers)
[![Total downloads](https://img.shields.io/github/downloads/bananaholograma/turnity/total.svg?label=Downloads&logo=github&cacheSeconds=600)](https://github.com/bananaholograma/turnity/releases)
[![License](https://img.shields.io/github/license/bananaholograma/turnity?cacheSeconds=2592000)](https://github.com/bananaholograma/turnity/blob/main/LICENSE.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat&logo=github)](https://github.com/bananaholograma/turnity/pulls)
</p>

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/bananaholograma/turnity/blob/main/README.md)

- - -
Tu plugin para una gestión de turnos optimizada en Godot. Eleva la experiencia de tu juego con una eficiente mecánica por turnos. Crea batallas dinámicas y escenarios atractivos sin esfuerzo.

- **Modos de turno flexibles**: Elige entre el modo en serie *(turnos uno tras otro)* y el modo de cola dinámica *(orden de turnos personalizable basado en una regla de ordenación en cada turno)*.
- **Parámetros configurables**: Ajusta la duración de los turnos, establece un número máximo de turnos, activa la progresión automática al siguiente turno y mucho más.
- **Ordenación dinámica**: Defina reglas de clasificación personalizadas para el orden de los turnos.
- **Fácil integración**: Integra Turnity con tu proyecto de Godot utilizando sólo 2 Nodos, conectando y desconectando TurnitySockets sin esfuerzo.

- - -

- [Requerimientos](#requerimientos)
- [✨Instalacion](#instalacion)
	- [Automatica (Recomendada)](#automatica-recomendada)
	- [Manual](#manual)
- [Como empezar](#como-empezar)
	- [Inicializar un nuevo sistema de turnos](#inicializar-un-nuevo-sistema-de-turnos)
	- [Utiliza las señales a su favor](#utiliza-las-señales-a-su-favor)
	- [Pasar manualmente al siguiente turno](#pasar-manualmente-al-siguiente-turno)
	- [Propiedades y señales disponibles](#propiedades-y-señales-disponibles)
	- [Métodos disponibles](#métodos-disponibles)
- [Como añadir un TurnitySocket](#como-añadir-un-turnitysocket)
	- [Via editor](#via-editor)
	- [Via script](#via-script)
	- [Duración del turno local](#duración-del-turno-local)
		- [Temporizador](#temporizador)
	- [Bloquear el socket N turnos](#bloquear-el-socket-n-turnos)
	- [Skip the turn](#skip-the-turn)
	- [Propiedades y señales disponibles](#propiedades-y-señales-disponibles-1)
	- [Available methods](#available-methods)
- [✌️Eres bienvenido a](#️eres-bienvenido-a)
- [🤝Normas de contribución](#normas-de-contribución)
- [📇Contáctanos](#contáctanos)

# Requerimientos
📢 No ofrecemos soporte para Godot 3+ ya que nos enfocamos en las versiones futuras estables a partir de la versión 4.
* Godot 4+

# ✨Instalacion
## Automatica (Recomendada)
Puedes descargar este plugin desde la [Godot asset library](https://godotengine.org/asset-library/asset/2570) oficial usando la pestaña AssetLib de tu editor Godot. Una vez instalado, estás listo para empezar
## Manual 
Para instalar manualmente el plugin, crea una carpeta **"addons"** en la raíz de tu proyecto Godot y luego descarga el contenido de la carpeta **"addons"** de este repositorio


# Como empezar
Este plugin te permite configurar un sistema basado en turnos aplicando nodos que llamaremos `TurnitySocket`. Cuando adjuntas este nodo en tu escena y vinculas un actor a él, es decir, el nodo al que pertenece *(jugador, enemigo, etc.)* entiende que debe ser añadido a la cola de turnos cuando se inicializa.

## Inicializar un nuevo sistema de turnos
Imagina que tu videojuego dispara un evento para iniciar una batalla, es en este momento cuando queremos inicializar el sistema de turnos con los miembros de esa batalla.

Puedes pasarle como parámetro el `nodo raíz` donde quieres que obtenga los sockets recursivamente. Si no se le pasa ningún valor utiliza `get_tree()` por defecto y recoge todas los `TurnitySocket` por su nombre de grupo *(definido internamente por el plugin).*

***Cada vez que la función `start()` es invocada, reinicia todos los parámetros internos, es bueno tener esto en cuenta para no reiniciar el sistema de turnos sin quererlo.***

El singleton `TurnityManager` permite establecer esta configuración usando sintaxis de encadenamiento como mostramos en el siguiente ejemplo:

```python
extends Node
##...

func _init_battle():
	TurnityManager.set_serial_mode()\
		.set_limited_turns(5)\
		.set_turn_duration(30)\
		.automatically_move_on_to_the_next_turn(false)\
		.set_sort_rule(your_custom_sort_function)\
		.start(self)


func your_custom_sort_function(socket_a: TurnitySocket, socket_b: TurnitySocket) -> void:
		## Escribe tu logica de ordenado aqui
		socket_a.actor.agility > socket_b.actor.agility
##...
```

**Puedes configurar:**
- El número de turnos que durará esta nueva "batalla", una vez consumido el último turno se emite la señal `finished`.
- La duración del turno en segundos, un temporizador automático es manejado por usted para terminar el turno cuando el contador llegue a cero.
- El siguiente turno puede ser automático o no, esto significa que si por ejemplo la duración del turno llega a cero se pasará al siguiente `TurnitySocket`
- El callback de ordenación se aplica para definir el orden de la cola de turnos, aplica tu propia lógica de ordenación que necesite tu juego.

## Utiliza las señales a su favor
Crea tu propio flujo de trabajo de sistema de turnos conectando a las señales del nodo `TurnitySocket` y reaccionando usando la lógica que tu videojuego necesite. Este plugin sólo ofrece una entrada muy simple para gestionar un conjunto de turnos, el resto depende de ti.

Las señales de `TurnityManager` son útiles para obtener esta información en otros lugares como la UI.

## Pasar manualmente al siguiente turno
El paso automático realmente sólo se aplica cuando la propiedad `turn_duration` es mayor que cero, para el resto debe aplicarse manualmente. Esto te permite aplicar la lógica necesaria de tu juego antes de pasar de turno.

Este método determina automáticamente según el modo seleccionado cual es el siguiente turno:


```python
TurnityManager.next_turn()

## And then access the new updated socket that represents the new turn
TurnityManager.current_turn_socket
```

## Propiedades y señales disponibles
Puedes recolectar toda la información necesaria a través de este nodo:

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

## Métodos disponibles
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
# Como añadir un TurnitySocket
Puedes tomar el camino manual añadiendolo desde el editor o a través de un script:

## Via editor

- ![turnity-socket-search](images/turnity-socket-search.png)

- ![turnity-socket-node](images/turnity-socket.png)

## Via script
```python
var socket = TurnitySocket.new()
socket.actor = <your_node>
add_child(socket)
```

No es necesario que el `TurnitySocket` sea hijo del nodo al que queremos adjuntarlo. Para ello disponemos de una variable exportable llamada `actor` en la que podemos asignar el nodo que queramos independientemente de la jerarquía.

## Duración del turno local
El plugin prioriza el valor de `turn duration` del socket local por lo que si establecemos una duración de turno global de **30 segundos** y establecemos esta variable en el `TurnitySocket` a **15 segundos** en el socket, esta última es la que se aplicará. 

***No se aplica si el valor del socket `turn_duration` es 0.***

### Temporizador
Se crea un temporizador cuando el nodo se añade al árbol de escena, si `automatic_move_on_to_the_next_turn` es true, cuando este temporizador alcance el tiempo de espera se moverá al siguiente giro automáticamente, si no, simplemente emitirá la señal `ended`.

Esto es útil para mostrar el tiempo usando nodos UI como mostramos en este ejemplo:

```python
extends Node

@onready var label = $Label

func _process(_delta):
	label.text = _format_seconds(TurnityManager.current_turn_socket.timer.time_left, false)
	
	
func _format_seconds(time : float, use_milliseconds : bool) -> String:
	var minutes := time / 60
	var seconds := fmod(time, 60)

	if not use_milliseconds:
		return "%02d:%02d" % [minutes, seconds]

	var milliseconds := fmod(time, 1) * 100

	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
```

## Bloquear el socket N turnos
Puedes bloquear el socket un número limitado de turnos en caso de que quieras aplicar algún tipo de efecto de anulación y evitar que la entidad consuma un turno. Este bloqueo se puede restablecer en cualquier momento con la función `reset_blocked_turns`.

Los turnos bloqueados son acumulativos por lo que si vuelves a llamar a la función se añadirán a los ya existentes:

```python
## Blocked 3 turns in a row
socket.block_a_number_of_turns(3)

## Amplify 2 more
socket.block_a_number_of_turns(2)
```

## Skip the turn
Puedes llamar a la función `skip()` para pasar literalmente al siguiente turno siempre que la variable `next_turn_when_skipped` sea verdadera, si no, simplemente emite la señal `skipped`.

## Propiedades y señales disponibles
```python
signal active_turn
signal ended_turn
signal changed_turn_duration(old_duration: int, new_duration: int)
signal reset_current_timer
signal blocked_n_turns(turns: int, total_turns: int)
signal blocked_turn_consumed(remaining_turns: int)
signal skipped
signal enabled_socket
signal disabled_socket

## The linked actor in the turn system
@export var actor: Node
## The turn duration for this socket, leave it to zero to make it infinite
@export var turn_duration := 0
## Automatically move on to next turn when this socket is skipped
@export var next_turn_when_skipped := true
## Automatically move on to next turn when this socket is blocked
@export var next_turn_when_blocked := true

var id: String
var timer: Timer
var active := false
var disabled := false
var blocked_turns := 0

```
## Available methods
```python
func change_turn_duration(new_duration: int) -> void
func reset_active_timer() -> void
func reset_blocked_turns():
func block_a_number_of_turns(turns: int) -> void
func is_blocked() -> bool
func skip()
func enable() -> void
func disable() -> void
func is_disabled()
```


# ✌️Eres bienvenido a
- [Give feedback](https://github.com/bananaholograma/turnity/pulls)
- [Suggest improvements](https://github.com/bananaholograma/turnity/issues/new?assignees=BananaHolograma&labels=enhancement&template=feature_request.md&title=)
- [Bug report](https://github.com/bananaholograma/turnity/issues/new?assignees=BananaHolograma&labels=bug%2C+task&template=bug_report.md&title=)

Este plugin esta disponible de forma gratuita.

Si estas agradecido por lo que hacemos, por favor, considera hacer una donación. Desarrollar los plugins y contenidos requiere una gran cantidad de tiempo y conocimiento, especialmente cuando se trata de Godot. Incluso 1€ es muy apreciado y demuestra que te importa. ¡Muchas Gracias!

- - -
# 🤝Normas de contribución
**¡Gracias por tu interes en este plugin!**

Para garantizar un proceso de contribución fluido y colaborativo, revise nuestras [directrices de contribución](https://github.com/bananaholograma/turnity/blob/main/CONTRIBUTING.md) antes de empezar. Estas directrices describen las normas y expectativas que mantenemos en este proyecto.

**📓Código de conducta:** En este proyecto nos adherimos estrictamente al [Código de conducta de Godot](https://godotengine.org/code-of-conduct/). Como colaborador, es importante respetar y seguir este código para mantener una comunidad positiva e inclusiva.
- - -


# 📇Contáctanos
Si has construido un proyecto, demo, script o algun otro ejemplo usando nuestros plugins haznoslo saber y podemos publicarlo en este repositorio para ayudarnos a mejorar y saber que lo que hacemos es útil.
