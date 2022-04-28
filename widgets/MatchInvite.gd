extends CenterContainer


var id
var username

func _ready():
	visible = false
	Net.connect("match_invite", self, "match_invite")
	
func match_invite(_id, _username):
	visible = true
	id = _id
	username = _username
	$PanelContainer/VBoxContainer/Info.text = "Player " + username + " has invited you to play with him " + _id

func _on_Accept_pressed():
	Net.match_join(id)
	visible = false

func _on_Reject_pressed():
	visible = false
	id = null
	username = null
