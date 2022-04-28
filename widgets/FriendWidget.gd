extends HBoxContainer

class_name FriendWidget

var id

func set_status(s):
	$Status.text = s
	
func set_username(s):
	$Username.text = s

func _on_Invite_pressed():
	Net.match_invite(id)
	$Invite.release_focus()
