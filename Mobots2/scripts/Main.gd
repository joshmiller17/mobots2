extends Node

export(PackedScene) var Signal

var tracks = []
var spawn_y = -500
var swipe_minimum = 100
var swipe_start
var max_dist = 200
var track_length
var data3 = File.new()  # 80 hz
var data4 = File.new()
var ninja
signal ninja_mode
signal ninja_off
var screen_center
var global_speed = 100
var selected
var score = 0

func _ready():
	# Center window
	var screen_size = OS.get_screen_size() #screen=0
	var window_size = OS.get_window_size()
	OS.set_window_position(screen_size*0.5 - window_size*0.5)
	screen_center = screen_size / 2
	track_length = window_size.x / 3
	tracks.append(track_length / 2)
	tracks.append(tracks[0] + track_length)
	tracks.append(tracks[1] + track_length)
	data3.open("res://assets/data3.csv", data3.READ)
	data4.open("res://assets/data4.csv", data4.READ)
	_on_SignalSpawner_timeout()

func _process(delta):
	pass
			
func _unhandled_input(event):
	if event.is_action_pressed("click"):
		swipe_start = event.position
	if event.is_action_released("click"):
		_calculate_swipe(event.position)

func _calculate_swipe(swipe_end):
	if swipe_start == null: 
		return
	var swipe = swipe_end - swipe_start
	if abs(swipe.x) > swipe_minimum:
		var dir = "none"
		if swipe.x < 0:
			dir = "left"
		else:
			dir = "right"
		var min_dist = 99999999
		var closest_signal
		for child in get_children():
			if child.get_filename() != Signal.get_path():
				continue # not a child we care about
			var dist = swipe_start.distance_to(child.position)
			if dist < min_dist:
				closest_signal = child
				min_dist = dist
		if not ninja:
			if min_dist < max_dist: # child found
				if dir == "left" and closest_signal.position.x > track_length:
					closest_signal.position.x -= track_length
					$Zip.play()
				elif dir == "right" and closest_signal.position.x < tracks[2]:
					closest_signal.position.x += track_length
					$Zip.play()
				else:
					pass # bad swipe
		else: # ninja swipe
			closest_signal = selected
			var cut_y = (swipe_start.y + swipe_end.y) / 2
			var length = len(closest_signal.find_node("X").points)
			var pos = closest_signal.find_node("X").to_global(closest_signal.find_node("X").position).y
			var index = (cut_y - pos) * 2
			if index > 0 and index < length:
				$Slice.play()
				var sig1 = Signal.instance()
				var sig2 = Signal.instance()
				sig1.set_position(Vector2(closest_signal.position.x, closest_signal.position.y - 20))
				sig2.set_position(Vector2(closest_signal.position.x, closest_signal.position.y + 20))

				var x1 = []
				var x2 = []
				var y1 = []
				var y2 = []
				var z1 = []
				var z2 = []
				for i in range(len(closest_signal.find_node("X").points)):
					if i < index:
						x1.append(closest_signal.find_node("X").points[i])
						y1.append(closest_signal.find_node("Y").points[i])
						z1.append(closest_signal.find_node("Z").points[i])
					else:
						x2.append(closest_signal.find_node("X").points[i])
						y2.append(closest_signal.find_node("Y").points[i])
						z2.append(closest_signal.find_node("Z").points[i])
						
				sig1.find_node("X").points = x1
				sig1.find_node("Y").points = y1
				sig1.find_node("Z").points = z1
				sig2.find_node("X").points = x2
				sig2.find_node("Y").points = y2
				sig2.find_node("Z").points = z2
			
				connect("ninja_mode", sig1, "on_ninja_mode")
				connect("ninja_mode", sig2, "on_ninja_mode")
				connect("ninja_off", sig1, "off_ninja_mode")
				connect("ninja_off", sig2, "off_ninja_mode")
				add_child(sig1)
				add_child(sig2)
				closest_signal.queue_free()
				$NinjaModeTimer.stop()
				emit_signal("ninja_off")
				ninja = false
				closest_signal = null

	else: # it's a click, not a swipe
		if not ninja:
			var dir = "none"
			var min_dist = 99999999
			var closest_signal
			for child in get_children():
				if child.get_filename() != Signal.get_path():
					continue # not a child we care about
				var dist = swipe_start.distance_to(child.position)
				if dist < min_dist:
					closest_signal = child
					min_dist = dist
			if min_dist < max_dist: # child found
				emit_signal("ninja_mode")
				$NinjaModeTimer.start()
				ninja = true
				closest_signal.ninja_select(screen_center / 2)
				selected = closest_signal

func success():
	score += 1
	$Correct.play()
	update_score()
	
func fail():
	score -= 1
	$Incorrect.play()
	update_score()
	
func update_score():
	get_node("/root/Main/CanvasLayer/HUD/ScoreLabel").set_text("SCORE: " + str(score))
	
func _on_SignalSpawner_timeout():
	$SignalSpawner.wait_time -= 0.05 # constantly get faster
	$NinjaModeTimer.wait_time -= 0.05 # constantly get faster
	global_speed += 1
	var sig = Signal.instance()
	var X_data = []
	var Y_data = []
	var Z_data = []
	var data
	if randf() < 0.5: # randomly select file
		data = data3
		sig.intensity = 0
	else:
		data = data4
		sig.intensity = 1
	for i in range(800):
		var pool = data.get_csv_line()
		X_data.append(Vector2(float(pool[0]) * 2.5, i/20))
		Y_data.append(Vector2(float(pool[1]) * 2.5, i/20))
		Z_data.append(Vector2(float(pool[2]) * 2.5, i/20))
	
	sig.find_node("X").points = X_data
	sig.find_node("Y").points = Y_data
	sig.find_node("Z").points = Z_data
	connect("ninja_mode", sig, "on_ninja_mode")
	connect("ninja_off", sig, "off_ninja_mode")
	add_child(sig)
	sig.set_position(Vector2(tracks[randi() % 3], spawn_y))


func _on_NinjaModeTimer_timeout():
	emit_signal("ninja_off")
	ninja = false
