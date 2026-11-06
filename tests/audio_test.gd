extends SceneTree

func _initialize() -> void:
	var script := load("res://scripts/audio_manager.gd")
	var audio: Node = script.new()
	var music: AudioStreamWAV = audio.call("build_music_stream")
	assert(music != null, "Music stream must be generated")
	assert(music.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Background music must loop")
	assert(music.data.size() > 100000, "Music stream must contain generated PCM audio")
	for kind in ["jump", "death", "trap", "complete"]:
		var effect: AudioStreamWAV = audio.call("build_sfx_stream", kind)
		assert(effect != null and effect.data.size() > 1000, "Every game event needs a generated sound")
	print("LEVEL DEVIL audio tests passed")
	audio.free()
	quit(0)
