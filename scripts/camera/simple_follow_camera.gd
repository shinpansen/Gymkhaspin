class_name SimpleFollowCamera
extends Camera3D

@export var vehicle_to_follow: Vehicle
@export var lerp_speed: float = 1.0
@export var fov_multiplier: float = 2.0

var _base_distance: float
var _base_y_gap: float
var _base_fov: float

func _ready() -> void:
	_base_fov = fov
	_base_y_gap = global_position.y - vehicle_to_follow.global_position.y
	_base_distance = global_position.distance_to(vehicle_to_follow.global_position)

func _process(delta: float) -> void:
	var fov_offset: float = vehicle_to_follow.current_acceleration * fov_multiplier
	if fov_offset < 0: fov_offset /= 2.0
	var traget_fov: float = _base_fov + fov_offset
	fov = lerpf(fov, traget_fov, delta * lerp_speed)

func _physics_process(delta: float) -> void:
	var target_position: Vector3 = vehicle_to_follow.global_position

	global_position = Vector3(
		global_position.x,
		target_position.y + _base_y_gap,
		global_position.z
	)

	look_at(target_position)

	if global_position.distance_to(target_position) != _base_distance:
		var direction: Vector3 = target_position.direction_to(global_position).normalized()
		global_position = target_position + direction * _base_distance
