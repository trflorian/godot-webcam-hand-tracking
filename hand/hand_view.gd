extends Node3D

class_name HandView

var landmark_scene: PackedScene = preload("res://hand/hand_landmark.tscn")

@export_enum("Left", "Right") var hand_side: String

var hand_landmarks: Array[HandLandmark] = []
var hand_lines: Array[MeshInstance3D] = []
var _is_tracking: bool = false
var _has_received_landmarks: bool = false

func _ready() -> void:
	_create_hand_landmark_nodes()
	_create_hand_lines()
	visible = false
	_set_colliders_enabled(false)

	var hand_tracker := get_node_or_null("/root/HandTracker") as HandTracker
	if hand_tracker != null:
		hand_tracker.hands_updated.connect(_on_hands_updated)

func _process(_delta: float) -> void:
	if not _has_received_landmarks:
		return
	_update_hand_lines()

func is_tracking() -> bool:
	return _is_tracking

func get_landmark_global_position(landmark_id: int) -> Vector3:
	if landmark_id < 0 or landmark_id >= hand_landmarks.size():
		return Vector3.ZERO
	return hand_landmarks[landmark_id].global_position

func update_from_landmarks(hand_data: MediaPipeNormalizedLandmarks) -> void:
	_is_tracking = hand_data != null
	if hand_data == null:
		return

	if not _has_received_landmarks:
		_has_received_landmarks = true
		visible = true
		_set_colliders_enabled(true)

	for lm_id in range(HandModel.NUM_LANDMARKS):
		var lm_data := hand_data.landmarks[lm_id]
		var world_position := HandModel.to_world_position(lm_data)
		hand_landmarks[lm_id].target = world_position

func _create_hand_landmark_nodes() -> void:
	for i in range(HandModel.NUM_LANDMARKS):
		var landmark_instance := landmark_scene.instantiate() as HandLandmark
		landmark_instance.from_landmark_id(i)
		add_child(landmark_instance)
		hand_landmarks.append(landmark_instance)

func _create_hand_lines() -> void:
	for _i in HandModel.HAND_LINES_MAPPING.size():
		var line_instance := MeshInstance3D.new()
		add_child(line_instance)
		hand_lines.append(line_instance)

func _update_hand_lines() -> void:
	for i in HandModel.HAND_LINES_MAPPING.size():
		var mapping: Array = HandModel.HAND_LINES_MAPPING[i]
		var p0 := hand_landmarks[mapping[0]].global_position
		var p1 := hand_landmarks[mapping[1]].global_position
		LineRenderer.edit_line(hand_lines[i], p0, p1)

func _set_colliders_enabled(enabled: bool) -> void:
	for hand_landmark in hand_landmarks:
		var collision_shape := hand_landmark.get_node("CollisionShape3D") as CollisionShape3D
		collision_shape.disabled = not enabled

func _on_hands_updated(left_hand_data: MediaPipeNormalizedLandmarks, right_hand_data: MediaPipeNormalizedLandmarks) -> void:
	var selected_data: MediaPipeNormalizedLandmarks = left_hand_data
	if hand_side == "Right":
		selected_data = right_hand_data
	update_from_landmarks(selected_data)
