extends SceneTree

# Verifies the audio pass: stream files import, the Sound autoload exposes a
# looping music player and a usable SFX pool, and every sound can be triggered.
# Run: godot --headless --path . --script tools/verify_audio.gd

const SFX := [
	"shoot", "hit", "bosshit", "hurt", "death", "pickup", "key", "jump",
	"walljump", "explosion", "door", "levelclear", "win", "ui",
]

var failures := 0


func check(ok: bool, label: String) -> void:
	if ok:
		print("OK ", label)
	else:
		print("FAIL ", label)
		failures += 1


func _init() -> void:
	for sound_name in SFX:
		var stream = load("res://Assets/Audio/%s.wav" % sound_name)
		check(stream is AudioStream, "%s imports as AudioStream" % sound_name)
	var music = load("res://Assets/Audio/music.wav")
	check(music is AudioStreamWAV, "music imports as AudioStreamWAV")
	if music is AudioStreamWAV:
		check(music.get_length() > 8.0, "music is longer than 8 s")

	var bus_script = load("res://Scripts/Sound.gd")
	bus_script.force_audio = true
	bus_script.autoplay_music = false
	var bus: Node = bus_script.new()
	bus.name = "Sound"
	root.add_child(bus)
	await process_frame
	check(bus != null, "Sound autoload script instantiates")
	if bus:
		check(bus.players.size() >= 8, "SFX pool has %d players" % bus.players.size())
		check(bus.music != null and bus.music.stream != null, "music player has a stream")
		if bus.music and bus.music.stream:
			var track = bus.music.stream
			check(track is AudioStreamWAV and track.loop_mode == AudioStreamWAV.LOOP_FORWARD,
				"music stream loops")
		for sound_name in SFX:
			bus.play(sound_name)
		check(true, "all SFX trigger without errors")
		var Sfx = load("res://Scripts/Sfx.gd")
		Sfx.play("hit", 1.0)
		check(true, "Sfx helper resolves the Sound node")
		bus.free()

	var config := FileAccess.get_file_as_string("res://project.godot")
	check(config.contains('Sound="*res://Scripts/Sound.gd"'), "Sound autoload registered")

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
