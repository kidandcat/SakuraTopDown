extends KinematicBody2D

var speed = 200  # speed in pixels/sec
var velocity = Vector2.ZERO
var current_animation
var attacking = false
var local = false

func _ready():
	add_to_group("players")
	set_process(false)
	set_physics_process(false)
	$Label.text = name

func main_player():
	local = true
	name = Net.username
	$Label.text = name
	Net.realtime_group_add("players")
	set_process(true)
	set_physics_process(true)

func hit():
	if not local: return
	set_process(false)
	set_physics_process(false)
	anim("die")

func sync_pos(x, y):
	if attacking: return
	var dx = x - global_position.x
	var dy = y - global_position.y
	if dx > 1:
		get_node("AnimatedSprite").flip_h = false
	elif dx < -1:
		get_node("AnimatedSprite").flip_h = true
	if dx > 1 or dy > 1:
		anim('walk')
	elif dx < -1 or dy < -1:
		anim('walk')
	else:
		anim('idle')
	global_position.x = x
	global_position.y = y

func get_input():
	if attacking: return
	velocity = Vector2.ZERO
	if Input.is_action_pressed('right'):
		velocity.x += 1
	if Input.is_action_pressed('left'):
		velocity.x -= 1
	if Input.is_action_pressed('down'):
		velocity.y += 1
	if Input.is_action_pressed('up'):
		velocity.y -= 1
	velocity = velocity.normalized() * speed
	if velocity.x > 1:
		$AnimatedSprite.flip_h = false
	elif velocity.x < -1:
		$AnimatedSprite.flip_h = true
	if velocity.x > 1 or velocity.y > 1:
		anim('walk')
	elif velocity.x < -1 or velocity.y < -1:
		anim('walk')
	else:
		anim('idle')
	if Input.is_action_just_pressed("attack"):
		attack()
		Net.sync_rpc("player", self, "", "attack")

func _process(_delta):
	Net.sync_pos("player", self, "")

func _unhandled_input(_event):
	get_input()

func _physics_process(_delta):
	velocity = move_and_slide(velocity)

func attack():
	attacking = true
	anim('attack')
	velocity = Vector2.ZERO
	if $AnimatedSprite.flip_h == true:
		var bs = $AttackLeft.get_overlapping_bodies()
		for b in bs:
			if b.has_method("hit"):
				b.hit()
	else:
		var bs = $AttackRight.get_overlapping_bodies()
		for b in bs:
			if b.has_method("hit"):
				b.hit()
	yield($AnimatedSprite, "animation_finished")
	attacking = false

func anim(animation):
	if current_animation != animation:
		$AnimatedSprite.play(animation)
		current_animation = animation
