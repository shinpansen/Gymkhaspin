extends Node3D

@export var score_target: int
@export var score_stream: AudioStreamPlayer
@export var score_volume: float = 0.9

const score_base: float = 10.0
const speed_multiplicator: float = 1.5
const distance_bonus: float = 10.0

var _in_area: bool
var _score: float = 0.0
var _vehicle: Vehicle = null
var _max_distance: float = 1.0

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	%ScoreLabel.text = str(int(_score)) + "/" + str(score_target)

	if _can_score():
		%CircleIndicator.visible = false
		%CircleIndicator2.visible = true
		_increase_score(delta)
	else:
		%CircleIndicator.visible = true
		%CircleIndicator2.visible = false
	
func _increase_score(delta: float) -> void:
	var previous_score: float = _score
	
	var vehicle_distance: float = _vehicle.global_position.distance_to(global_position)
	var bonus_distance_ratio: float = 1.0 - (vehicle_distance / _max_distance)
	var bonus: float = score_base
	bonus += distance_bonus * bonus_distance_ratio
	bonus *= 1.0 + _vehicle.speed / 25.0
	_score += bonus * delta
	if _score > score_target: _score = score_target

	# Sound
	if int(previous_score) % 2 != 0 && int(_score) % 2 == 0:
		score_stream.volume_db = SoundsUtils.get_volume_db(score_volume)
		score_stream.play()

func _can_score() -> bool:
	return (
		_in_area && 
		_score < score_target &&
		_vehicle.is_drifting &&
		_vehicle.speed >= 4.0
	)

func _on_score_area_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if !(body is Vehicle): return
	_max_distance = body.global_position.distance_to(global_position)
	_vehicle = body as Vehicle
	_in_area = true

func _on_score_area_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if !(body is Vehicle): return
	_vehicle = null
	_in_area = false
