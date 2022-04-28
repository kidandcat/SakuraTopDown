extends VBoxContainer

const cFriendWidget = preload("res://widgets/FriendWidget.tscn")
const cFriendRequestWidget = preload("res://widgets/FriendRequestWidget.tscn")

func _ready():
	Net.connect("friend", self, "friend")
	Net.connect("friend_request", self, "friend_request")
	Net.list_friends()
	Net.list_friend_requests()

func friend(id, username, status):
	for c in get_children():
		if c is FriendWidget and c.id == id:
			c.queue_free()
	var f = cFriendWidget.instance()
	f.set_username(username)
	f.set_status(status)
	f.id = id
	add_child(f)
	
func friend_request(id, username):
	for c in get_children():
		if c is FriendRequestWidget and c.id == id:
			c.queue_free()
	var f = cFriendRequestWidget.instance()
	f.set_username("Inv: " + username)
	f.id = id
	add_child(f)
	move_child(f, 0)

func _on_AddFriend_pressed():
	var us = $FriendName.text
	if us.length() < 4:
		return
	Net.friend_request(us)
