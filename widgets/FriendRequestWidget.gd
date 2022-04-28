extends HBoxContainer

class_name FriendRequestWidget

var id
	
func set_username(s):
	$Username.text = s

func _on_Accept_pressed():
	Net.friend_accept(id)
	queue_free()

func _on_Reject_pressed():
	Net.friend_remove(id)
	queue_free()
