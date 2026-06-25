class_name LerpExtension

static func lerp_vector2(source: Vector2, target: Vector2, weight: float) -> Vector2:
	return Vector2(
		lerp(source.x, target.x, weight), 
		lerp(source.y, target.y, weight))

static func lerp_vector3(source: Vector3, target: Vector3, weight: float) -> Vector3:
	return Vector3(
		lerp(source.x, target.x, weight), 
		lerp(source.y, target.y, weight), 
		lerp(source.z, target.z, weight))

static func lerp_angle_vector2(source: Vector2, target: Vector2, weight: float) -> Vector2:
	source = Vector2(MathUtils.deg2rad(source.x), MathUtils.deg2rad(source.y))
	target = Vector2(MathUtils.deg2rad(target.x), MathUtils.deg2rad(target.y))
	return Vector2(
		MathUtils.rad2deg(lerp_angle(source.x, target.x, weight)), 
		MathUtils.rad2deg(lerp_angle(source.y, target.y, weight)))

static func lerp_angle_vector3(source: Vector3, target: Vector3, weight: float) -> Vector3:
	source = Vector3(MathUtils.deg2rad(source.x), MathUtils.deg2rad(source.y), MathUtils.deg2rad(source.z))
	target = Vector3(MathUtils.deg2rad(target.x), MathUtils.deg2rad(target.y), MathUtils.deg2rad(target.z))
	return Vector3(
		MathUtils.rad2deg(lerp_angle(source.x, target.x, weight)), 
		MathUtils.rad2deg(lerp_angle(source.y, target.y, weight)), 
		MathUtils.rad2deg(lerp_angle(source.z, target.z, weight)))
        