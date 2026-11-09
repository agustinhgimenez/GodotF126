extends Node
## Conexión con el servidor de salas online (autoload "Online"). Un WebSocket con mensajes
## JSON: browse() pide la lista de salas abiertas ("rooms", que el servidor vuelve a mandar
## cada vez que cambia), create_room() abre una sala con sus reglas y join_room() entra a una.
## Cuando hay dos en la sala llega "matched" con el rival y las reglas (pista, vueltas, clima,
## neumáticos); lo demás ("s" estado, "fin" llegada, "go" largada, "left" el rival se fue)
## llega por `message`. Sigue funcionando con el árbol en pausa.

signal status_changed(text: String)
signal rooms_changed(rooms: Array)
signal matched(slot: int, opponent: Dictionary, settings: Dictionary)
signal message(msg: Dictionary)
## La conexión se cortó o el servidor rechazó el pedido (reason para mostrar).
signal failed(reason: String)

const DATA_PATH := "res://data/online.json"
const MAX_NAME := 16

enum State { IDLE, CONNECTING, BROWSING, HOSTING, JOINING, MATCHED }

var state: State = State.IDLE
## 0 = el que creó la sala (larga adelante), 1 = el que se unió.
var slot: int = -1
var opponent: Dictionary = {}
var settings: Dictionary = {}
var rooms: Array = []
var data: Dictionary = {}
## s de ida y vuelta al servidor (el último ping).
var rtt: float = 0.1

var _socket: WebSocketPeer
var _request: Dictionary = {}
var _ping_timer: float = 0.0
var _was_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	data = DataLoader.load_json(DATA_PATH)
	set_process(false)


func server_url() -> String:
	var args := OS.get_cmdline_user_args()
	for k in args.size() - 1:
		if args[k] == "--server":
			return args[k + 1]
	return str(data.get("server_url", ""))


func is_matched() -> bool:
	return state == State.MATCHED


## Nombre con el que juega (Settings "player_name"); si está vacío se inventa uno y se guarda.
func player_name() -> String:
	var name := clean_name(str(Settings.get_value("player_name")))
	if name.is_empty():
		name = "Jugador %d" % (randi() % 900 + 100)
		Settings.set_value("player_name", name)
	return name


func clean_name(text: String) -> String:
	return text.strip_edges().left(MAX_NAME)


## Lista de salas abiertas: llega por rooms_changed y se actualiza sola mientras se mira.
func browse() -> void:
	_open({"t": "list"}, "Buscando salas…")


## player: {name, driver_id, driver_name, team_id}; rules: {track, laps, weather, compound}.
func create_room(player: Dictionary, rules: Dictionary) -> void:
	_open({"t": "create", "player": player, "settings": rules}, "Creando la sala…")


func join_room(room_id: int, player: Dictionary) -> void:
	_open({"t": "join", "room": room_id, "player": player}, "Entrando a la sala…")


func send(msg: Dictionary) -> void:
	if _socket != null and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_socket.send_text(JSON.stringify(msg))


## Avisa al servidor (se cierra la sala propia o el rival recibe "left") y cierra.
func leave() -> void:
	if _socket != null:
		send({"t": "leave"})
		_socket.poll()
		_socket.close()
		_socket.poll()
	_socket = null
	state = State.IDLE
	slot = -1
	opponent = {}
	rooms = []
	set_process(false)


## Cada pedido usa una conexión nueva (la anterior se cierra).
func _open(request: Dictionary, status: String) -> void:
	leave()
	_request = request
	_request["v"] = int(data.get("protocol", 2))
	_socket = WebSocketPeer.new()
	var error := _socket.connect_to_url(server_url())
	if error != OK:
		_socket = null
		_fail("No se pudo conectar con el servidor (%d)" % error)
		return
	state = State.CONNECTING
	_was_open = false
	_ping_timer = 0.0
	set_process(true)
	status_changed.emit(status)


func _process(delta: float) -> void:
	if _socket == null:
		return
	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _was_open:
				_was_open = true
				send(_request)
				send({"t": "ping", "c": Time.get_ticks_msec()})
				match str(_request.get("t", "")):
					"list":
						state = State.BROWSING
					"create":
						state = State.HOSTING
					"join":
						state = State.JOINING
			while _socket != null and _socket.get_available_packet_count() > 0:
				var parsed = JSON.parse_string(_socket.get_packet().get_string_from_utf8())
				if parsed is Dictionary:
					_handle(parsed)
			if _socket == null:
				return
			_ping_timer += delta
			if _ping_timer >= float(data.get("ping_interval", 10.0)):
				_ping_timer = 0.0
				send({"t": "ping", "c": Time.get_ticks_msec()})
		WebSocketPeer.STATE_CLOSED:
			var reason := "Se perdió la conexión con el servidor" if _was_open else "No se pudo conectar con el servidor"
			_socket = null
			_fail(reason)


func _handle(msg: Dictionary) -> void:
	match str(msg.get("t", "")):
		"rooms":
			var list = msg.get("rooms", [])
			rooms = list.filter(func(r) -> bool: return r is Dictionary) if list is Array else []
			rooms_changed.emit(rooms)
		"created":
			status_changed.emit("Sala creada · esperando a que alguien se una…")
		"matched":
			slot = int(msg.get("slot", 0))
			var who = msg.get("opponent", {})
			opponent = who if who is Dictionary else {}
			var rules = msg.get("settings", {})
			settings = rules if rules is Dictionary else {}
			state = State.MATCHED
			matched.emit(slot, opponent, settings)
		"error":
			var reason := str(msg.get("reason", "Error del servidor"))
			leave()
			failed.emit(reason)
		"pong":
			if msg.has("c"):
				rtt = clampf((Time.get_ticks_msec() - float(msg["c"])) / 1000.0, 0.0, 2.0)
		_:
			message.emit(msg)


func _fail(reason: String) -> void:
	state = State.IDLE
	set_process(false)
	failed.emit(reason)
