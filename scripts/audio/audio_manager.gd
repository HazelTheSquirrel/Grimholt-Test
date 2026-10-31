extends Node
const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 8
var players: Array[AudioStreamPlayer] = []
var next_player: int = 0
var streams: Dictionary = {}
func _ready() -> void:
	for index in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		players.append(player)
	streams["shot"] = _make_tone(145.0, 0.075, 0.55, 0.25)
	streams["hit"] = _make_tone(760.0, 0.055, 0.0, 0.18)
	streams["reload"] = _make_tone(310.0, 0.16, 0.0, 0.14)
	streams["damage"] = _make_tone(92.0, 0.22, 0.25, 0.24)
	streams["wave"] = _make_tone(520.0, 0.32, 0.0, 0.12)
func play_sfx(kind: String) -> void:
	if not streams.has(kind) or players.is_empty():
		return
	var player: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stop()
	player.stream = streams[kind] as AudioStreamWAV
	player.play()
func _make_tone(frequency: float, duration: float, noise_mix: float, volume: float) -> AudioStreamWAV:
	var sample_count: int = int(SAMPLE_RATE * duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in range(sample_count):
		var time: float = float(index) / float(SAMPLE_RATE)
		var envelope: float = pow(1.0 - float(index) / float(sample_count), 2.0)
		var tone: float = sin(TAU * frequency * time) * (1.0 - noise_mix)
		var noise: float = sin(TAU * (frequency * 2.73) * time) * noise_mix
		var sample: float = clampf((tone + noise) * envelope * volume, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(sample * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
