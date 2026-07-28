extends Node

var _streams: Dictionary = {}

func _ready() -> void:
	_streams["attack"] = _make_tone(520.0, 0.08, 0.20)
	_streams["heavy"] = _make_tone(170.0, 0.16, 0.28)
	_streams["dash"] = _make_tone(760.0, 0.10, 0.18)
	_streams["hit"] = _make_tone(110.0, 0.13, 0.30)
	_streams["break"] = _make_tone(85.0, 0.22, 0.32)
	_streams["artifact"] = _make_tone(880.0, 0.34, 0.18)
	_streams["seal"] = _make_tone(1040.0, 0.25, 0.17)
	_streams["duel"] = _make_tone(240.0, 0.38, 0.22)
	_streams["parry"] = _make_tone(1320.0, 0.09, 0.24)
	_streams["win"] = _make_tone(660.0, 0.42, 0.20)

func play_cue(cue: String) -> void:
	if not _streams.has(cue):
		return
	var player := AudioStreamPlayer.new()
	player.stream = _streams[cue]
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := maxi(1, int(duration * float(stream.mix_rate)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var progress := float(index) / float(sample_count)
		var envelope := (1.0 - progress) * (1.0 - progress)
		var sample := int(sin(TAU * frequency * float(index) / float(stream.mix_rate)) * 32767.0 * volume * envelope)
		data[index * 2] = sample & 0xff
		data[index * 2 + 1] = (sample >> 8) & 0xff
	stream.data = data
	return stream
