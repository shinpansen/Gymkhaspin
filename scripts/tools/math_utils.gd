class_name MathUtils

static func deg2rad(deg: float) -> float:
	return deg * PI / 180.0

static func rad2deg(rad: float) -> float:
	return rad * 180.0 / PI

static func get_position_on_circle(center: Vector3, radius: float, angle_deg: float) -> Vector3:
	var angle_rad = deg_to_rad(angle_deg)
	var x = center.x + cos(angle_rad) * radius
	var z = center.z + sin(angle_rad) * radius
	return Vector3(x, center.y, z)
