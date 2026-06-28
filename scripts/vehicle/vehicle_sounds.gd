class_name VehicleSounds
extends Node

@export var vehicle_source: Vehicle

@export_group("Engine")
@export var engine_sounds: Dictionary[int, AudioStream]
@export_range(0.0, 1.0) var engine_volume: float = 1.0

@export_group("Drift")
@export var drif_stream: AudioStreamPlayer
@export_range(0.0, 1.0) var drift_volume: float = 0.66
@export var drift_fade_time: float = 20.0

var _engine_stream_players: Dictionary[int, AudioStreamPlayer] = {}
var _min_rpm_key: int = 9999999
var _max_rpm_key: int = -9999999
var _start_sound_tween: Tween
var _end_sound_tween: Tween

func _ready() -> void:
	for key in engine_sounds.keys():
		if key < _min_rpm_key: _min_rpm_key = key
		if key > _max_rpm_key: _max_rpm_key = key
		var player := AudioStreamPlayer.new()
		add_child(player)
		player.stream = engine_sounds[key]
		player.volume_db = -80.0
		_engine_stream_players[key] = player

	for player in _engine_stream_players.values():
		player.play()

func _process(delta: float) -> void:
	_play_engine_sound(delta)
	# _play_drift_sound(delta)

func _play_engine_sound(delta) -> void:
	if vehicle_source == null: return

	# Upper and lower engine sound calculus regarding rpm
	var rpm: float = max(vehicle_source.rpm, vehicle_source.idle_rpm)
	var lower_rpm: float = clamp(floor(rpm / 500.0) * 500.0, _min_rpm_key, _max_rpm_key)
	var upper_rpm: float = clamp(lower_rpm + 500.0, _min_rpm_key, _max_rpm_key)
	var rpm_ratio: float = clamp((rpm - lower_rpm) / 500.0, 0.0, 1.0)
	var lower_stream_player: AudioStreamPlayer = _engine_stream_players.get(int(lower_rpm))
	var upper_stream_player: AudioStreamPlayer = _engine_stream_players.get(int(upper_rpm))
	
	# Stopping unused stream
	for key in _engine_stream_players.keys():
		if key != int(lower_rpm) && key != int(upper_rpm):
			_engine_stream_players[key].pitch_scale = 1.0
			_engine_stream_players[key].volume_db = -80.0

	# Pitch and volume
	lower_stream_player.volume_db = linear_to_db(clamp((1.0 - rpm_ratio) * engine_volume, 0.01, 1.0))
	upper_stream_player.volume_db = linear_to_db(clamp(rpm_ratio * engine_volume, 0.01, 1.0))
	lower_stream_player.pitch_scale = rpm / lower_rpm
	upper_stream_player.pitch_scale = rpm / upper_rpm

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
		delta * drift_fade_time
	)

func stop_drift_sound(player: AudioStreamPlayer, delta: float):
	if !player.playing: player.play()
	if _start_sound_tween != null && _start_sound_tween.is_running():
		_start_sound_tween.stop()
	elif _end_sound_tween != null && _end_sound_tween.is_running(): 
		return

	_end_sound_tween = create_tween()
	_end_sound_tween.tween_property(player, "volume_db", -80.0, delta * drift_fade_time)
