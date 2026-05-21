extends Node3D

class_name Hand

const NUM_LANDMARKS: int = 21
const HAND_SCALE: float = 30.0

const HAND_LINES_MAPPING = [
	[0, 1], [1, 2], [2, 3], [3, 4], # Thumb
	[0, 5], [5, 6], [6, 7], [7, 8], # Index Finger
	[5, 9], [9, 10], [10, 11], [11, 12], # Middle Finger
	[9, 13], [13, 14], [14, 15], [15, 16], # Ring Finger
	[0, 17], [13, 17], [17, 18], [18, 19], [19, 20], # Pinky
]

var landmark_sphere: PackedScene = preload("res://hand/hand_landmark.tscn")
var bullet: PackedScene = preload("res://bullet/bullet.tscn")

var hand_landmarks: Array[HandLandmark] = []
var hand_lines: Array[MeshInstance3D] = []

var pew_audio_stream_player: AudioStreamPlayer

func _ready() -> void:
	_create_hand_landmark_spheres()
	_create_hand_lines()
	
	# by default hide
	visible = false

func _create_hand_landmark_spheres() -> void:
	for i in range(NUM_LANDMARKS):
		var landmark_instance = landmark_sphere.instantiate() as HandLandmark
		landmark_instance.from_landmark_id(i)
		add_child(landmark_instance)
		hand_landmarks.append(landmark_instance)

func _create_hand_lines() -> void:
	for i in HAND_LINES_MAPPING.size():
		var line_instance := MeshInstance3D.new()
		add_child(line_instance)
		hand_lines.append(line_instance)

func _process(_delta: float) -> void:
	_update_hand_lines()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.keycode == KEY_SPACE:
			var bullet_inst: Bullet = bullet.instantiate()
			add_child(bullet_inst)
			var dir = (hand_landmarks[8].global_position - hand_landmarks[7].global_position).normalized()
			dir.z = 0
			bullet_inst.direction = dir  
			bullet_inst.global_position = hand_landmarks[8].global_position + dir
			
			if dir.length() > 0:
				bullet_inst.look_at(bullet_inst.global_position + dir, Vector3.UP)
			
			pew_audio_stream_player.pitch_scale = randf_range(0.95, 1.05)
			pew_audio_stream_player.play()

func _update_hand_lines() -> void:
	for i in HAND_LINES_MAPPING.size():
		var mapping = HAND_LINES_MAPPING[i]
		var p0 = hand_landmarks[mapping[0]].global_position
		var p1 = hand_landmarks[mapping[1]].global_position
		LineRenderer.edit_line(hand_lines[i], p0, p1)

func _update_hand_landmark(landmark_id: int, landmark_pos: Vector3) -> void:
	var lm = hand_landmarks[landmark_id]
	lm.target = landmark_pos

func parse_hand_landmarks_from_data(hand_data: MediaPipeNormalizedLandmarks) -> void:
	visible = hand_data != null
	
	if not hand_data:
		return
	
	for lm_id in range(NUM_LANDMARKS):
		var lm_data := hand_data.landmarks[lm_id]
		
		var cam_xy = Vector2(lm_data.x, lm_data.y) - 0.5 * Vector2.ONE
		cam_xy *= HAND_SCALE
		var pos_xyz = Vector3(-cam_xy.x, -cam_xy.y, lm_data.z)
		_update_hand_landmark(lm_id, pos_xyz)
