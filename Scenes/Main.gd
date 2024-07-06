extends Node2D

var last_time = 0;
var notes_on = []
var point_scene = preload("res://Scenes/Point.tscn")
var duckie_scene = preload("res://Scenes/Duckie.tscn")
var timer_offset = 5860 # about 6s to notes
var time2space = 500
var current_time2space = 0

var mscIntro
var mscLoop
var midi
var current_music

# Called when the node enters the scene tree for the first time.
func _ready():
	mscIntro = $musicIntro
	mscLoop = $musicLoop
	midi = $MidiPlayer
	midi.note.connect(my_note_callback)
	midi.play()
	midi.manual_process = true
	current_music = mscIntro
	current_music.play()
	current_time2space = $Measure.position.x + $Measure.get_node('Measure').texture.get_width()
	spawn_duckie()

func _on_music_loop_finished():
	print("Looping MIDI")
	last_time = 0
	midi.stop() # resets time and other important variables
	midi.play() # plays midi
	# play audio stream
	current_music = mscLoop
	current_music.play()
	spawn_duckie()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# get asp playback time
	var time = current_music.get_playback_position() + AudioServer.get_time_since_last_mix()
	# Compensate for output latency.
	time -= AudioServer.get_output_latency()
	
	# tick the midi player with the delta from our audio stream player
	# this syncs the midi player with the audio server
	# this is a more accurate way of doing it than using the delta from _process
	var asp_delta = time - last_time
	last_time = time
	midi.process_delta(asp_delta)
	
	current_time2space -= asp_delta * time2space
	print(current_time2space)
	
	for note in notes_on:
		note.position.x -= asp_delta * time2space
		if note.position.x < 150:
			var index = notes_on.find(note)
			if index != -1:
				notes_on.remove_at(index)
				note.queue_free()

func my_note_callback(event, track):
	if (event['subtype'] == MIDI_MESSAGE_NOTE_ON): # note on
		spawn_point()
		## do something on note on
	#elif (event['subtype'] == MIDI_MESSAGE_NOTE_OFF): 
		#notes.find({"note": event['note']})# note off
		#notes.remove_at()
	#	print("noteoff")
	#print("[Track: " + str(track) + "] Note played: " + str(event['note']))

func spawn_duckie():
	var factor = $DuckieContainer.get_child_count()
	var duckie = duckie_scene.instantiate()
	duckie.position.x = factor * 200
	$DuckieContainer.add_child(duckie)
	
func spawn_point():
	var point = point_scene.instantiate()
	var spawn_x = $Measure.position.x + $Measure.get_node('Measure').texture.get_width()
	point.audio_position = current_music.get_playback_position()
	point.position.x = spawn_x + 100
	point.position.y = 210
	point.scale = Vector2(0.5, 0.5)
	add_child(point)
	notes_on.push_back(point)

func _on_music_intro_finished():
	print("going to loop")
	spawn_duckie()
	midi.stop()
	midi.play()
	current_music = mscLoop
	current_music.play()

func _on_midi_player_meta(meta):
	print(meta)
