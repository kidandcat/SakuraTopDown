extends Node2D

const cPlayer = preload("res://Player.tscn")
const cSlime = preload("res://Enemy.tscn")
var invite_match

func _ready():
	if invite_match:
		Net.match_join(invite_match)
	else:
		Net.match_create(Net.username)
	Net.sync_config("player", cPlayer)
	Net.sync_config("slime", cSlime)
	Net.connect("error", self, "error")
	$Player.main_player()
	create_enemy()
	
var enemies = 0
func create_enemy():
	if enemies < 5:
		enemies += 1
		var e = cSlime.instance()
		e.global_position = $EnemySpawnPoint1.global_position
		add_child(e)
		e.control_local()
		e.connect("tree_exited", self, "killed_enemy")

func killed_enemy():
	enemies -= 1

func error(err):
	print(err)


func _on_EnemySpawner_timeout():
	create_enemy()

