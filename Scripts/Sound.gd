extends Node

## Autoload audio bus: pooled SFX players plus one looping music player.

const SFX := [
	"shoot", "hit", "bosshit", "hurt", "death", "pickup", "key", "jump",
	"walljump", "explosion", "door", "levelclear", "win", "ui",
]
const POOL_SIZE := 10

static var force_audio := false
static var autoplay_music := true

var streams := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music: AudioStreamPlayer


func _ready() -> void:
	if DisplayServer.get_name() == "headless" and not force_audio:
		return
	for sound_name in SFX:
		streams[sound_name] = load("res://Assets/Audio/%s.wav" % sound_name)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		players.append(player)
	music = AudioStreamPlayer.new()
	music.bus = &"Master"
	music.volume_db = -12.0
	add_child(music)
	var track: AudioStreamWAV = load("res://Assets/Audio/music.wav")
	if track:
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD
		track.loop_begin = 0
		track.loop_end = int(track.get_length() * track.mix_rate)
		music.stream = track
		if autoplay_music:
			music.play()


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	var stream: AudioStream = streams.get(sound)
	if stream == null or players.is_empty():
		return
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func stop_music() -> void:
	if music:
		music.stop()


func _exit_tree() -> void:
	stop_music()
	for player in players:
		player.stop()
		player.stream = null
	streams.clear()
	if music:
		music.stream = null
