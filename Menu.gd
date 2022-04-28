extends Control


onready var input_user = $HBoxContainer/VBoxContainer/User
onready var input_pass = $HBoxContainer/VBoxContainer/Pass
onready var info = $HBoxContainer/VBoxContainer/Info

func _ready():
	Net.connect("realtime_ready", self, "realtime_ready")
	Net.connect("register_success", self, "register_success")
	Net.connect("error", self, "error")

func _on_login_pressed():
	Net.auth(input_user.text, input_pass.text)

func _on_register_pressed():
	Net.register(input_user.text, input_pass.text)

func realtime_ready():
	info.text = "Logged in!!"
	get_tree().change_scene("res://Game.tscn")

func register_success():
	info.text = "Registered!!"

func error(err):
	info.text = err
