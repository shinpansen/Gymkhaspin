class_name Wheel
extends Node3D

@export var parent_vehicle: Vehicle
@export var suspension_length: float = 0.7
@export var suspension_force: float = 150.0
@export var wheel_min_offset_y: float = -0.2
@export var skid_mark_path_name: String
@export var skid_mark_points_gap: float = 0.2
@export var skid_mark_points_count: int = 100
@export var steering_wheel: bool
@export var driving_wheel: bool = true

var skid_mark_started: bool:
	get: return _skid_mark_started
	set(_value): assert(false, "skid_mark_started is read-only")

var wheel_boxing: Node3D
var wheel_mesh: MeshInstance3D

var _raycast: RayCast3D
var _wheel_radius: float
var _wheel_distance_to_raycast: float
var _skid_mark_curve: Curve3D
var _skid_mark_started: bool

func _ready() -> void:
	wheel_boxing = %WheelBoxing
	wheel_mesh = %WheelMesh
	_raycast = %RayCast3D
	_wheel_radius = wheel_mesh.get_aabb().size.y / 2.0
	_wheel_distance_to_raycast = _raycast.global_position.distance_to(wheel_mesh.global_position)

func _process(delta: float) -> void:
	if parent_vehicle == null: return

	if on_ground(): _apply_suspension_force(delta)
	_update_wheel_offset(delta)

func on_ground() -> bool:
	if !_raycast.is_colliding(): return false
	elif _get_suspension_distance_to_collision() > suspension_length: return false
	return true

func start_skid_mark() -> void:
	_skid_mark_started = true
	_skid_mark_curve = SkidMarksFactory.request_path(self).curve

func draw_skid_mark() -> void:
	if !_skid_mark_started: return
	elif !on_ground(): 
		end_skid_mark()
		return
	
	var hit_point: Vector3 = _raycast.get_collision_point()
	var last_point: Vector3 = Vector3.ZERO
	if _skid_mark_curve.point_count > 0:
		last_point = _skid_mark_curve.get_point_position(_skid_mark_curve.point_count-1)
	if last_point != Vector3.ZERO && hit_point.distance_to(last_point) < skid_mark_points_gap:
		return
	
	_skid_mark_curve.add_point(hit_point)
	
func end_skid_mark() -> void:
	_skid_mark_started = false

func _apply_suspension_force(delta: float) -> void:
	var hit_distance: float = _get_suspension_distance_to_collision()
	var hit_point: Vector3 = _raycast.get_collision_point()
	var force_ratio: float = 1.0 - (hit_distance / suspension_length)
	var direction: Vector3 = hit_point.direction_to(_raycast.global_position).normalized()
	parent_vehicle.apply_force(
		direction * force_ratio * suspension_force,
		_raycast.global_position - parent_vehicle.global_position
	)
	
func _get_suspension_distance_to_collision() -> float:
	if !_raycast.is_colliding(): return suspension_length;
	return _raycast.global_position.distance_to(_raycast.get_collision_point())
	
func _update_wheel_offset(delta: float) -> void:
	if !on_ground():
		wheel_mesh.position.y = lerpf(wheel_mesh.position.y, wheel_min_offset_y, delta * 20.0)
	else:
		var distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
		distance -= _wheel_distance_to_raycast
		wheel_mesh.position.y = lerpf(wheel_mesh.position.y, -distance + _wheel_radius, delta * 20.0)
