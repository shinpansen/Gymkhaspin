class_name VehicleSounds
extends Node

@export var vehicle_source: Vehicle
@export var drif_stream: AudioStreamPlayer
@export var engine_stream: AudioStreamPlayer
@export_range(0.0, 1.0) var drift_volume: float = 0.66
@export_range(0.0, 1.0) var engine_volume: float = 1.0
@export var fade_time: float = 20.0

var _start_sound_tween: Tween
var _end_sound_tween: Tween

func _process(delta: float) -> void:
    _play_engine_sound(delta)
    _play_drift_sound(delta)

func _play_engine_sound(delta) -> void:
    print(engine_stream.pitch_scale)
    var speed_base: float = vehicle_source.speed if vehicle_source.is_on_ground else 23.0
    if vehicle_source.is_drifting: speed_base *= 1.5
    var pitch: float = (0.25 + (speed_base + 0.1) / 25.0) * 3.0
    engine_stream.pitch_scale = lerpf(engine_stream.pitch_scale, pitch, delta * 5.0)
    engine_stream.volume_db = SoundsUtils.get_volume_db(engine_volume)
    if !engine_stream.playing: engine_stream.play()

func _play_drift_sound(delta: float) -> void:
    if vehicle_source.is_drawing_skid_marks:
        start_drift_sound(drif_stream, delta)
        var pitch: float = (0.5 + vehicle_source.speed / 25.0) * 1.5
        drif_stream.pitch_scale = lerpf(drif_stream.pitch_scale, pitch, delta * 10.0)
    else:
        stop_drift_sound(drif_stream, delta)

func start_drift_sound(player: AudioStreamPlayer, delta: float):
    if !player.playing: player.play()
    if _end_sound_tween != null && _end_sound_tween.is_running():
        _end_sound_tween.stop()
    elif _start_sound_tween != null && _start_sound_tween.is_running(): 
        return

    _start_sound_tween = create_tween()
    _start_sound_tween.tween_property(
        player, 
        "volume_db", 
        SoundsUtils.get_volume_db(drift_volume), 
        delta * fade_time
    )

func stop_drift_sound(player: AudioStreamPlayer, delta: float):
    if !player.playing: player.play()
    if _start_sound_tween != null && _start_sound_tween.is_running():
        _start_sound_tween.stop()
    elif _end_sound_tween != null && _end_sound_tween.is_running(): 
        return

    _end_sound_tween = create_tween()
    _end_sound_tween.tween_property(player, "volume_db", -80.0, delta * fade_time)
