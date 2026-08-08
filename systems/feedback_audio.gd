extends Node
class_name FeedbackAudio

func play_tone(frequency: float, duration: float, volume_db := -12.0) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var samples := PackedByteArray()
	var sample_count := int(stream.mix_rate * duration)
	for index in sample_count:
		var envelope := 1.0 - (float(index) / float(sample_count))
		var sample := int(sin(float(index) * TAU * frequency / stream.mix_rate) * 11000.0 * envelope)
		samples.append(sample & 255)
		samples.append((sample >> 8) & 255)
	stream.data = samples
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume_db
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
