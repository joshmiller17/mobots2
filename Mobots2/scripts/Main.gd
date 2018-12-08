extends Node

export(PackedScene) var Signal

var tracks = []
var spawn_y = 0 # -300
var swipe_minimum = 100
var swipe_start
var max_dist = 200
var track_length

func _ready():
	# Center window
	var screen_size = OS.get_screen_size() #screen=0
	var window_size = OS.get_window_size()
	OS.set_window_position(screen_size*0.5 - window_size*0.5)
	track_length = window_size.x / 3
	tracks.append(track_length / 2)
	tracks.append(tracks[0] + track_length)
	tracks.append(tracks[1] + track_length)

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
		if min_dist < max_dist: # child found
			if dir == "left" and closest_signal.position.x > track_length:
				closest_signal.position.x -= track_length
			elif dir == "right" and closest_signal.position.x < tracks[2]:
				closest_signal.position.x += track_length
			else:
				pass # TODO bad swipe


func _on_SignalSpawner_timeout():
	$SignalSpawner.wait_time -= 0.01 # constantly get faster
	var sig = Signal.instance()
	add_child(sig)
	# TODO sig data
	sig.set_position(Vector2(tracks[randi() % 3], spawn_y))
