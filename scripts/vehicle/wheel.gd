class_name Wheel
extends Node3D

@export var parent_vehicle: Vehicle
@export var suspension_length: float = 0.6
@export var suspension_force: float = 180.0

var _raycast: RayCast3D

func _ready() -> void:
	_raycast = %RayCast3D

func _process(delta: float) -> void:
	if parent_vehicle == null: return

	_handle_suspension(delta)

func _handle_suspension(delta: float) -> void:
	# update_wheel_global_position(wheel_component, delta)

	var current_distance_to_collision: float = _get_suspension_distance_to_collision()
	if !_raycast.is_colliding(): return

	if current_distance_to_collision > suspension_length: return

	var collision_point: Vector3 = _raycast.get_collision_point()
	var force_ratio: float = 1.0 - (
		current_distance_to_collision /
		suspension_length
	)

	var direction: Vector3 = collision_point.direction_to(
		_raycast.global_position).normalized()


	parent_vehicle.apply_force(
		direction * force_ratio * suspension_force,
		_raycast.global_position - parent_vehicle.global_position
	)
 
func _get_suspension_distance_to_collision() -> float:
	if !_raycast.is_colliding(): return suspension_length;
	return _raycast.global_position.distance_to(_raycast.get_collision_point())
