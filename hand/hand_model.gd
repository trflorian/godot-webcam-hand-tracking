extends RefCounted

class_name HandModel

const NUM_LANDMARKS: int = 21
const HAND_SCALE: float = 30.0

const HAND_LINES_MAPPING := [
	[0, 1], [1, 2], [2, 3], [3, 4],
	[0, 5], [5, 6], [6, 7], [7, 8],
	[5, 9], [9, 10], [10, 11], [11, 12],
	[9, 13], [13, 14], [14, 15], [15, 16],
	[0, 17], [13, 17], [17, 18], [18, 19], [19, 20],
]

static func to_world_position(landmark: MediaPipeNormalizedLandmark) -> Vector3:
	var camera_xy := Vector2(landmark.x, landmark.y) - 0.5 * Vector2.ONE
	camera_xy *= HAND_SCALE
	return Vector3(-camera_xy.x, -camera_xy.y, landmark.z)
