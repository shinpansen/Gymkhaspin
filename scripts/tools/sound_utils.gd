class_name SoundsUtils

static func get_volume_db(volume: float) -> float:
    return -(80.0 - (80.0 * volume))