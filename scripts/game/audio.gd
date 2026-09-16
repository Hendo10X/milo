extends Node
## Autoload (Audio). One place to play sounds and music.
##
##   Audio.play("perfect")          # plays res://assets/audio/sfx/perfect.wav
##   Audio.play("land", 0.9, 1.1)   # with a random pitch range so repeats
##                                  # don't sound mechanical
##   Audio.play_music("loop")       # loops res://assets/audio/music/loop.wav
##
## Sound effects are looked up by file name, so adding a new sound is just
## dropping a .wav or .ogg into assets/audio/sfx/ and calling play() with
## its name. A missing file is skipped (with a warning) so the game never
## breaks because an asset is not there yet.
##
## Buses: Master → Music, SFX (see default_bus_layout.tres). Volumes are
## saved in the same config file as the best score.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const EXTENSIONS := ["wav", "ogg"]
## How many effects can overlap before the oldest one is cut off.
const SFX_VOICES := 8

var music_volume := 0.7:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume("Music", music_volume)
var sfx_volume := 1.0:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume("SFX", sfx_volume)

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _streams := {}  # name -> AudioStream (cached)
var _next_voice := 0


func _ready() -> void:
	# Keep playing while the game is paused so menu sounds work.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)


func _exit_tree() -> void:
	# Release streams before the AudioServer shuts down so quitting mid-sound
	# does not report leaked resources.
	for p in _sfx_players:
		p.stop()
		p.stream = null
	_music_player.stop()
	_music_player.stream = null
	_streams.clear()


## Play a one-shot effect. `pitch_min`/`pitch_max` randomise the pitch.
func play(sound_name: String, pitch_min := 1.0, pitch_max := 1.0, volume_db := 0.0) -> void:
	var stream := _load(SFX_DIR, sound_name)
	if stream == null:
		return
	var p := _sfx_players[_next_voice]
	_next_voice = (_next_voice + 1) % SFX_VOICES
	p.stream = stream
	p.pitch_scale = randf_range(pitch_min, pitch_max)
	p.volume_db = volume_db
	p.play()


## Start (or switch) looping music. Same track keeps playing uninterrupted.
func play_music(track_name: String, fade := 0.6) -> void:
	var stream := _load(MUSIC_DIR, track_name)
	if stream == null or _music_player.stream == stream:
		return
	_set_loop(stream)
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	create_tween().tween_property(_music_player, "volume_db", 0.0, fade)


func stop_music(fade := 0.6) -> void:
	if not _music_player.playing:
		return
	var t := create_tween()
	t.tween_property(_music_player, "volume_db", -40.0, fade)
	t.tween_callback(_music_player.stop)


func _load(dir: String, sound_name: String) -> AudioStream:
	if _streams.has(sound_name):
		return _streams[sound_name]
	for ext: String in EXTENSIONS:
		var path := dir + sound_name + "." + ext
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			_streams[sound_name] = stream
			return stream
	push_warning("Audio: no file for '%s' in %s" % [sound_name, dir])
	_streams[sound_name] = null
	return null


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		(stream as AudioStreamWAV).loop_end = (stream as AudioStreamWAV).data.size() / 2
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _apply_bus_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
