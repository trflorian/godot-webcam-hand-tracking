extends Node3D

class_name HandsView

@onready var left_hand_view: HandView = $LeftHandView
@onready var right_hand_view: HandView = $RightHandView

func update_hands(left_hand_data: MediaPipeNormalizedLandmarks, right_hand_data: MediaPipeNormalizedLandmarks) -> void:
	left_hand_view.update_from_landmarks(left_hand_data)
	right_hand_view.update_from_landmarks(right_hand_data)

func get_primary_hand() -> HandView:
	if right_hand_view.is_tracking():
		return right_hand_view
	if left_hand_view.is_tracking():
		return left_hand_view
	return null
