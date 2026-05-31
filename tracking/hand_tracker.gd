extends Node

signal hands_updated(left_hand: MediaPipeNormalizedLandmarks, right_hand: MediaPipeNormalizedLandmarks)
signal hands_visible_changed(has_hands: bool)
signal status_changed(text: String)

@export var task_file: String = "res://tasks/hand_landmarker.task"

var task: MediaPipeHandLandmarker
var _has_hands: bool = false
var _received_result: bool = false

func _ready() -> void:
	_init_task()
	var camera_source := get_node_or_null("/root/CameraSource") as CameraSource
	if camera_source != null:
		camera_source.frame_ready.connect(process_frame)

func _init_task() -> void:
	status_changed.emit("Loading Mediapipe Task file...")
	var file := _load_model(task_file)
	if file == null:
		printerr("failed to load model from task file %s" % str(task_file))
		status_changed.emit("Failed to load Mediapipe task file...")
		return

	var base_options := MediaPipeTaskBaseOptions.new()
	base_options.delegate = MediaPipeTaskBaseOptions.DELEGATE_CPU
	base_options.model_asset_buffer = file.get_buffer(file.get_length())

	task = MediaPipeHandLandmarker.new()
	task.initialize(base_options, MediaPipeVisionTask.RUNNING_MODE_LIVE_STREAM, 2, 0.4, 0.4, 0.4)
	task.result_callback.connect(self._result_callback)
	status_changed.emit("")

func process_frame(image: Image) -> void:
	if task == null:
		return
	var mp_image := MediaPipeImage.new()
	mp_image.set_image(image)
	task.detect_async(mp_image, Time.get_ticks_msec())

func _result_callback(result: MediaPipeHandLandmarkerResult, _image: MediaPipeImage, _timestamp_ms: int) -> void:
	var left_hand_landmarks: MediaPipeNormalizedLandmarks = null
	var right_hand_landmarks: MediaPipeNormalizedLandmarks = null

	assert(len(result.handedness) == len(result.hand_landmarks))
	for i in range(len(result.handedness)):
		var category_name: String = result.handedness[i].categories[0].category_name
		if left_hand_landmarks == null and category_name == "Left":
			left_hand_landmarks = result.hand_landmarks[i]
		if right_hand_landmarks == null and category_name == "Right":
			right_hand_landmarks = result.hand_landmarks[i]

	hands_updated.emit(left_hand_landmarks, right_hand_landmarks)
	var has_hands := len(result.hand_landmarks) > 0
	if not _received_result or has_hands != _has_hands:
		_received_result = true
		_has_hands = has_hands
		hands_visible_changed.emit(has_hands)

func _load_model(path: String) -> FileAccess:
	assert(FileAccess.file_exists(path), "task file %s does not exist" % path)
	return FileAccess.open(path, FileAccess.READ)
