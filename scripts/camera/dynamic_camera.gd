class_name DynamicCamera
extends Camera3D

@export var vehicle_to_follow: Vehicle
@export var distance: float = 2.2
@export var height: float = 1.5
@export var camera_speed: float = 8.0
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
	var forward: Vector3 = vehicle_to_follow.global_transform.basis.z.normalized()
	forward.y = 0.0
	if vehicle_to_follow.signed_speed > 1.0: forward *= -1.0
	var target_position: Vector3 = vehicle_to_follow.global_position
	target_position -= forward * distance
	target_position.y += height
	global_position = LerpExtension.lerp_vector3(global_position, target_position, camera_speed * delta)
	look_at(vehicle_to_follow.global_position)
