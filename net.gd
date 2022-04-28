extends Node

# - - Sakura config - -
var api_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiQVBJIiwic2VydmljZXMiOiJkYXRhLHBsYXllcixyZWFsdGltZSIsInVpZCI6IjAyMDAyYTI3LTU3MzQtNGQ0MC05NTkyLTM5YzI4NzcwYzkwNiJ9.PiFoq2clvq0a5hjInT4FxvA6E-A3bWl4xg3a_ZNKdBQ"
var websocket_url = "wss://sakura.galax.be/services/api"
var realtime_websocket_url = "wss://sakura.galax.be/realtime/api"

#var websocket_url = "ws://localhost:3000/services/api"
#var realtime_websocket_url = "ws://localhost:3000/realtime/api"

# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -
# - - - - - - - - - - -

var ws = WebSocketClient.new()
var realtime_ws = WebSocketClient.new()
var sync_entities = {}
var username = ""
var my_sid

signal register_success
signal realtime_ready
signal auth_ok
signal error(err)
signal realtime(data)
signal friend(id, username, status)
signal friend_request(id, username)
signal match_invite(id, username)
signal match_joined(id, username)
signal match_leaved(id, username)

func _ready():
	ws.connect("connection_closed", self, "_closed")
	ws.connect("connection_error", self, "_closed")
	ws.connect("connection_established", self, "_connected")
	ws.connect("data_received", self, "_on_data")
	
	realtime_ws.connect("connection_closed", self, "_realtime_closed")
	realtime_ws.connect("connection_error", self, "_realtime_closed")
	realtime_ws.connect("connection_established", self, "_realtime_connected")
	realtime_ws.connect("data_received", self, "_realtime_on_data")
	
	_conn()

func _conn():
	var err = ws.connect_to_url(websocket_url,[],false,PoolStringArray(["API-Token: " + api_token]))
	if err != OK:
		print("Unable to connect ", err)
		
func _realtime_conn():
	var err = realtime_ws.connect_to_url(realtime_websocket_url,[],false,PoolStringArray(["API-Token: " + api_token, "SID: " + my_sid]))
	if err != OK:
		print("Realtime unable to connect ", err)

func _closed(was_clean = false):
	print("Disconnected, retrying in 2s")
	yield(get_tree().create_timer(2.0), "timeout")
	_conn()

func _realtime_closed(was_clean = false):
	print("Realtime disconnected, retrying in 2s")
	yield(get_tree().create_timer(2.0), "timeout")
	_realtime_conn()

func _connected(proto = ""):
	print("connected")
	
func _realtime_connected(proto = ""):
	print("realtime connected")
	emit_signal("realtime_ready")
	realtime_ws.get_peer(1).set_no_delay(true)
	
func _process(_delta):
	realtime_ws.poll()
	
func _physics_process(_delta):
	ws.poll()
	
# Commands
func auth(email: String, password: String):
	username = email
	var msg = "player::auth::" + email + "::" + password
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func register(email: String, password: String):
	var msg = "player::register::" + email + "::" + password
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func list_friends():
	var msg = "player::friends"
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func list_friend_requests():
	var msg = "player::friend_requests"
	ws.get_peer(1).put_packet(msg.to_utf8())

func friend_request(friendID: String):
	var msg = "player::friend_request::" + friendID
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func friend_accept(friendID: String):
	var msg = "player::friend_accept::" + friendID
	print(msg)
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func friend_remove(friendID: String):
	var msg = "player::friend_remove::" + friendID
	ws.get_peer(1).put_packet(msg.to_utf8())

func match_create(_name):
	var msg = "player::match_create::" + _name
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func match_leave():
	var msg = "player::match_leave"
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func match_invite(player_id):
	var msg = "player::match_invite::" + player_id
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func match_get():
	var msg = "player::match_get"
	ws.get_peer(1).put_packet(msg.to_utf8())
	
func match_join(id):
	var msg = "player::match_join::" + str(id)
	ws.get_peer(1).put_packet(msg.to_utf8())

# Realtime
var pause
func realtime_reliable(data: String, group = ""):
	var msg = "reliable::" + group + "::" + data
	realtime_ws.get_peer(1).put_packet(msg.to_utf8())

func realtime_unreliable(data: String, group = ""):
	var msg = "unreliable::" + group + "::" + data
	realtime_ws.get_peer(1).put_packet(msg.to_utf8())

func realtime_group_add(group: String):
	var msg = "group_add::" + group
	realtime_ws.get_peer(1).put_packet(msg.to_utf8())

func realtime_group_remove(group: String):
	var msg = "group_remove::" + group
	realtime_ws.get_peer(1).put_packet(msg.to_utf8())
	
# Receivers
func _on_data():
	var msg = ws.get_peer(1).get_packet().get_string_from_utf8()
	var m = msg.split("::")
	print(m)
	match m[0]:
		"error":
			emit_signal("error", m[1])
		"player":
			match m[1]:
				"error":
					emit_signal("error", m[2])
				"register_success":
					emit_signal("register_success")
				"auth_ok":
					emit_signal("auth_ok")
					my_sid = m[2]
					print("auth_ok, connecting realtime")
					_realtime_conn()
				"friend":
					emit_signal("friend", m[2], m[3], m[4])
				"friend_request":
					emit_signal("friend_request", m[2], m[3])
				"match_invite":
					emit_signal("match_invite", m[2], m[3])
				"match_joined":
					emit_signal("match_joined", m[2], m[3])
				"match_leaved":
					emit_signal("match_leaved", m[2], m[3])

func _realtime_on_data():
	var msg = realtime_ws.get_peer(1).get_packet().get_string_from_utf8()
	var m = msg.split(":")
	match m[0]:
		"sync_pos":
			var ename = m[1]
			if not sync_entities.has(ename): return
			if not Net.username.validate_node_name() in m[2]:
				var n = get_node_or_null(m[2])
				if not n:
					n = sync_entities[ename]["pack"].instance()
					n.name = nodename(m[2])
					get_node(node_to_path(m[2])).add_child(n)
				n.sync_pos(float(m[3]), float(m[4]))
		"sync_rpc":
			var ename = m[1]
			if not sync_entities.has(ename): return
			var id = m[2].validate_node_name()
			if not Net.username.validate_node_name() in id:
				var n = get_node_or_null(m[2])
				if not n:
					n = sync_entities[ename]["pack"].instance()
					n.name = nodename(m[2])
					get_node(node_to_path(m[2])).add_child(n)
				n.call(m[3]) 
		_:
			emit_signal("realtime", msg)


# Godot utilities
func sync_pos(ename: String, entity: Node2D, extraname: String):
	Net.realtime_unreliable("sync_pos:" + ename +":" + NodePath_to_path(entity.get_path()) + Net.username.validate_node_name() + extraname + ":" + str(entity.global_position.x) + ":" + str(entity.global_position.y))

func sync_rpc(ename: String, entity: Node2D, extraname: String, function: String):
	Net.realtime_reliable("sync_rpc:" + ename +":" + NodePath_to_path(entity.get_path()) + Net.username.validate_node_name() + extraname + ":" + function)

func sync_config(ename: String, entityPacked: PackedScene):
	sync_entities[ename] = {
		"pack": entityPacked
	}

func NodePath_to_path(np: NodePath):
	var c = np.get_name_count()
	var path = "/"
	for n in c-1:
		path += np.get_name(n) + "/"
	return path

func node_to_path(nps: String):
	var np = NodePath(nps)
	var c = np.get_name_count()
	var path = "/"
	for n in c-1:
		path += np.get_name(n) + "/"
	return path

func nodename(nps: String):
	var np = NodePath(nps)
	return np.get_name(np.get_name_count()-1)
