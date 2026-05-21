extends Node3D

var camera_feed: CameraFeed

var task: MediaPipeHandLandmarker
var task_file := "res://tasks/hand_landmarker.task"

@onready var camera_view: TextureRect = $CameraCanvasLayer/CameraView
@onready var camera_viewport: SubViewport = $CameraViewport
@onready var camera_texture: TextureRect = $CameraViewport/CameraSurface

var is_showing_webcam: bool = false

var left_hand: Hand
var right_hand: Hand

func _result_callback(result: MediaPipeHandLandmarkerResult, image: MediaPipeImage, _timestamp_ms: int) -> void:
	show_result(image, result)

func _init_task() -> void:
	var file := load_model(task_file)
	if file == null:
		printerr("failed to load model from task file %s" % str(task_file))
		return
	var base_options := MediaPipeTaskBaseOptions.new()
	base_options.delegate = MediaPipeTaskBaseOptions.DELEGATE_CPU
	base_options.model_asset_buffer = file.get_buffer(file.get_length())
	task = MediaPipeHandLandmarker.new()
	task.initialize(base_options, MediaPipeVisionTask.RUNNING_MODE_LIVE_STREAM, 2, 0.25, 0.25, 0.25)
	task.result_callback.connect(self._result_callback)
	
func _ready() -> void:
	_init_task()
	_start_camera()
	
	left_hand = _create_new_hand()
	right_hand = _create_new_hand()

func _create_new_hand() -> Hand:
	var hand_instance := Hand.new()
	add_child(hand_instance)
	return hand_instance
	
func _start_camera() -> void:
	CameraServer.monitoring_feeds = true
	await CameraServer.camera_feeds_updated
	var num_cameras = CameraServer.get_feed_count()
	if num_cameras == 0:
		print("no camera found")
		return
	camera_feed = CameraServer.get_feed(0)
	print("found %d cameras, using first camera '%s'" % [num_cameras, camera_feed.get_name()])
	camera_feed.format_changed.connect(self._camera_format_changed, ConnectFlags.CONNECT_DEFERRED)
	camera_feed.frame_changed.connect(self._camera_frame_changed, ConnectFlags.CONNECT_DEFERRED)
	
	# find best format
	var formats := camera_feed.get_formats()
	var best_format_idx := argmax_camera_format(formats)

	print("using format %s" % formats[best_format_idx])
	camera_feed.set_format(best_format_idx, {})

	camera_feed.feed_is_active = true

const FORMAT_RANKING := {
	"YUYV 4:2:2": 1,
	"Motion-JPEG": -1,
}

func _fps_from_format(format: Dictionary) -> int:
	if format.has("frame_numerator") and format.has("frame_denominator"):
		return round(format["frame_denominator"] / format["frame_numerator"])
	if format.has("framerate_numerator") and format.has("framerate_denominator"):
		return round(format["framerate_numerator"] / format["framerate_denominator"])
	printerr("no fps found in foramt: ", format)
	return 0

func _compare_formats(a: Dictionary, b: Dictionary) -> bool:
	var format_rank = FORMAT_RANKING.get(a.format, 0) - FORMAT_RANKING.get(b.format, 0)
	if format_rank != 0:
		return format_rank > 0
	var frame_rank = _fps_from_format(a) - _fps_from_format(b)
	if frame_rank != 0:
		return frame_rank > 0
	var area_rank = a.width * a.height - b.width * b.height
	if area_rank != 0:
		return area_rank > 0
	return false

func argmax_camera_format(formats: Array) -> int:
	var best_format_idx = 0
	var best_format = formats[0]
	for i in range(1, formats.size()):
		if _compare_formats(formats[i], best_format):
			best_format = formats[i]
			best_format_idx = i
	return best_format_idx

func _camera_format_changed() -> void:
	if camera_feed == null:
		return
	print("camera format changed to %s" % camera_feed.get_datatype())
	assert(camera_feed.get_datatype() == CameraFeed.FEED_RGB, "camera feed must be RGB8")

	var texture_rgb := CameraTexture.new()
	texture_rgb.camera_feed_id = camera_feed.get_id()
	texture_rgb.which_feed = CameraServer.FEED_RGBA_IMAGE

	var frame_size = texture_rgb.get_size()

	camera_texture.material = null
	camera_texture.texture = texture_rgb

	var feed_rotation: float = camera_feed.feed_transform.get_rotation()
	if camera_texture.flip_h:
		feed_rotation *= -1

	var size_rotated := Vector2(frame_size).rotated(feed_rotation)
	var offset := Vector2(min(size_rotated.x, 0), min(size_rotated.y, 0))

	camera_texture.rotation = feed_rotation
	camera_texture.position = offset * -1
	
	camera_viewport.size = frame_size
		
func _camera_frame_changed() -> void:
	await RenderingServer.frame_post_draw
	
	if not camera_view.visible:
		camera_view.visible = true
	
	var texture := camera_viewport.get_texture()

	var image := texture.get_image()
	#image.convert(Image.FORMAT_RGBA8) # GPU
	image.convert(Image.FORMAT_RGB8) # CPU

	var mp_image := MediaPipeImage.new()
	mp_image.set_image(image)

	task.detect_async(mp_image, Time.get_ticks_msec())

func load_model(path: String) -> FileAccess:
	assert(FileAccess.file_exists(path), "task file %s does not exist" % path)
	return FileAccess.open(path, FileAccess.READ)

func show_result(output: MediaPipeImage, result: MediaPipeHandLandmarkerResult) -> void:
	var image = output.image
	
	var should_show_camera = len(result.hand_landmarks) == 0
	
	if not should_show_camera:
		print(result.handedness[0].head_index)
		right_hand.parse_hand_landmarks_from_data(result.hand_landmarks[0])
	
	if not is_showing_webcam and should_show_camera:
		is_showing_webcam = true
		var tween = get_tree().create_tween()
		tween.tween_property(camera_view, "modulate", Color(1,1,1,1), 1.0)
		tween.set_ease(Tween.EASE_IN_OUT)
	if is_showing_webcam and not should_show_camera:
		is_showing_webcam = false
		var tween = get_tree().create_tween()
		tween.tween_property(camera_view, "modulate", Color(1,1,1,0), 1.0)
		tween.set_ease(Tween.EASE_IN_OUT)
	
	image.convert(Image.FORMAT_RGB8)
