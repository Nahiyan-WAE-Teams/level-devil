extends Node
class_name DevilAudio

const SAMPLE_RATE := 22050
const MUSIC_SECONDS := 12.8

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "AmbientMusic"
	music_player.stream = build_music_stream()
	music_player.volume_db = -19.0
	add_child(music_player)
	music_player.play()

func play_sfx(kind: String) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = build_sfx_stream(kind)
	player.volume_db = -7.0 if kind != "death" else -3.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func build_music_stream() -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * MUSIC_SECONDS)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var chords := [
		PackedFloat32Array([130.81, 155.56, 196.00]),
		PackedFloat32Array([110.00, 130.81, 164.81]),
		PackedFloat32Array([116.54, 146.83, 174.61]),
		PackedFloat32Array([98.00, 123.47, 146.83])
	]
	for frame in range(frame_count):
		var time := float(frame) / SAMPLE_RATE
		var bar := int(time / 3.2) % chords.size()
		var local_time := fposmod(time, 3.2)
		var fade := minf(1.0, time / 1.2) * minf(1.0, (MUSIC_SECONDS - time) / 1.2)
		var slow_pulse := 0.78 + 0.22 * sin(TAU * local_time / 3.2)
		var sample := 0.0
		for note in chords[bar]:
			sample += sin(TAU * note * time) * 0.055
			sample += sin(TAU * note * 2.003 * time) * 0.012
		var bass_note: float = chords[bar][0] * 0.5
		sample += sin(TAU * bass_note * time) * 0.11
		sample *= slow_pulse * fade
		sample = clampf(sample, -0.8, 0.8)
		data.encode_s16(frame * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	stream.data = data
	return stream

func build_sfx_stream(kind: String) -> AudioStreamWAV:
	var duration := 0.22
	match kind:
		"jump":
			duration = 0.18
		"death":
			duration = 0.52
		"complete":
			duration = 0.72
		"trap":
			duration = 0.26
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for frame in range(frame_count):
		var progress := float(frame) / float(frame_count)
		var time := float(frame) / SAMPLE_RATE
		var envelope := pow(1.0 - progress, 1.8)
		var frequency := 220.0
		var sample := 0.0
		match kind:
			"jump":
				frequency = lerpf(230.0, 620.0, progress)
				sample = sin(TAU * frequency * time) * 0.45
			"death":
				frequency = lerpf(390.0, 62.0, progress)
				sample = (sin(TAU * frequency * time) * 0.65 + sin(TAU * frequency * 0.5 * time) * 0.25)
			"complete":
				sample = (sin(TAU * 392.0 * time) + sin(TAU * 493.88 * time) + sin(TAU * 587.33 * time)) * 0.18
			"trap":
				frequency = lerpf(180.0, 75.0, progress)
				sample = sin(TAU * frequency * time) * 0.38
			_:
				sample = sin(TAU * frequency * time) * 0.25
		sample *= envelope
		data.encode_s16(frame * 2, int(clampf(sample, -0.9, 0.9) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
