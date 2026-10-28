extends Node
# Original, procedural retro audio for the Wildbound prototype.
# Generated in memory; no external music or copyrighted game samples.

const SAMPLE_RATE: int = 11025
const NOTE_SECONDS: float = 0.25
var music_player: AudioStreamPlayer
var fx_player: AudioStreamPlayer
var tracks: Dictionary = {}
var effects: Dictionary = {}
var current_track: String = ""
var muted: bool = false

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.volume_db = -18.0
    add_child(music_player)
    fx_player = AudioStreamPlayer.new()
    fx_player.volume_db = -12.0
    add_child(fx_player)

func play_track(theme: String) -> void:
    if theme == current_track:
        return
    current_track = theme
    if not tracks.has(theme):
        tracks[theme] = _compose(theme)
    music_player.stop()
    music_player.stream = tracks[theme]
    if not muted:
        music_player.play()

func play_fx(kind: String) -> void:
    if muted:
        return
    if not effects.has(kind):
        effects[kind] = _effect(kind)
    fx_player.stop()
    fx_player.stream = effects[kind]
    fx_player.play()

func toggle_mute() -> bool:
    muted = not muted
    music_player.volume_db = -80.0 if muted else -18.0
    fx_player.volume_db = -80.0 if muted else -12.0
    if muted:
        music_player.stop()
    elif music_player.stream != null:
        music_player.play()
    return muted

func _compose(theme: String) -> AudioStreamWAV:
    # Each melody is original, 16 eighth-note pulses looping at four seconds.
    var melody: Array[int] = [64, 67, 69, 67, 72, 69, 67, 64, 62, 64, 67, 69, 67, 64, 62, 60]
    if theme == "world":
        melody = [60, 64, 67, 69, 72, 69, 67, 64, 65, 69, 72, 74, 72, 69, 67, 64]
    elif theme == "battle":
        melody = [57, 60, 64, 69, 67, 64, 60, 62, 57, 60, 65, 69, 67, 65, 64, 60]
    var count: int = int(float(SAMPLE_RATE) * NOTE_SECONDS * float(melody.size()))
    var raw: PackedByteArray = PackedByteArray()
    raw.resize(count * 2)
    for i in range(count):
        var t: float = float(i) / float(SAMPLE_RATE)
        var note_idx: int = mini(melody.size() - 1, int(t / NOTE_SECONDS))
        var pitch: float = 440.0 * pow(2.0, (float(melody[note_idx]) - 69.0) / 12.0)
        var pulse: float = fmod(t, NOTE_SECONDS) / NOTE_SECONDS
        var envelope: float = 0.25 + 0.75 * (1.0 - pulse)
        var lead: float = sin(TAU * pitch * t) * 0.57 + sin(TAU * pitch * 2.0 * t) * 0.12
        var bass_pitch: float = pitch * 0.25
        var bass: float = sin(TAU * bass_pitch * t) * 0.22
        var sample: float = clampf((lead * envelope + bass) * 0.25, -0.95, 0.95)
        raw.encode_s16(i * 2, int(sample * 32767.0))
    return _make_wav(raw, true, count)

func _effect(kind: String) -> AudioStreamWAV:
    var duration: float = 0.22
    var start_hz: float = 540.0
    var end_hz: float = 280.0
    if kind == "capture":
        duration = 0.38
        start_hz = 450.0
        end_hz = 850.0
    elif kind == "evolve":
        duration = 0.62
        start_hz = 370.0
        end_hz = 970.0
    elif kind == "victory":
        duration = 0.5
        start_hz = 540.0
        end_hz = 820.0
    elif kind == "confirm":
        duration = 0.10
        start_hz = 620.0
        end_hz = 790.0
    elif kind == "break":
        duration = 0.24
        start_hz = 650.0
        end_hz = 170.0
    var count: int = int(float(SAMPLE_RATE) * duration)
    var raw: PackedByteArray = PackedByteArray()
    raw.resize(count * 2)
    for i in range(count):
        var t: float = float(i) / float(SAMPLE_RATE)
        var fraction: float = t / duration
        var chirp: float = TAU * (start_hz * t + 0.5 * (end_hz - start_hz) * t * fraction)
        var wave: float = sin(chirp) + 0.24 * sin(chirp * 2.0)
        var sample: float = clampf(wave * (1.0 - fraction) * 0.30, -0.95, 0.95)
        raw.encode_s16(i * 2, int(sample * 32767.0))
    return _make_wav(raw, false, count)

func _make_wav(raw: PackedByteArray, looped: bool, samples: int) -> AudioStreamWAV:
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = raw
    if looped:
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_begin = 0
        stream.loop_end = samples
    return stream
