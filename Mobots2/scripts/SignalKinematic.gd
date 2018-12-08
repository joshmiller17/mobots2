extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var g_speed
var speed
var selected = false
var old_pos = Vector2(0,0)
var intensity = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	g_speed = get_node("/root/Main").global_speed
	if get_node("/root/Main").ninja:
		speed = g_speed / 4
	else:
		speed = g_speed

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	if not selected:
		position.y += speed * delta
	else:
		old_pos.y += speed * delta
	if position.y > 700:
		if not intensity:
			if position.x < 500:
				get_node("/root/Main").success()
			else:
				get_node("/root/Main").fail()
		else:
			if position.x < 500:
				get_node("/root/Main").fail()
			else:
				get_node("/root/Main").success()
		queue_free()
		
	
func on_ninja_mode():
	speed = g_speed / 4
	
func off_ninja_mode():
	speed = g_speed
	if selected:
		selected = false
		position = old_pos
		scale = Vector2(1,1)
	
func ninja_select(new_pos):
	selected = true
	old_pos = position
	scale = Vector2(3,3)
	position = new_pos
