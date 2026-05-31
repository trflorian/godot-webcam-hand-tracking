extends Node

signal frame_ready(image: Image)
signal status_changed(text: String)

const FORMAT_RANKING := {
	"YUV_420_888": 2,
	"YUYV 4:2:2": 1,
	"Motion-JPEG": -1,
}
const TARGET_CAMERA_SIZE := Vector2i(1280, 720)

@export var ycbcr_shader: Shader = preload("res://camera/ycbcr_to_rgb.gdshader")

var camera_feed: CameraFeed
var camera_viewport: SubViewport
var camera_surface: TextureRect

func _ready() -> void:
	_create_processing_nodes()
	_start()

func _create_processing_nodes() -> void:
	camera_viewport = SubViewport.new()
	camera_viewport.name = "CameraViewport"
	camera_viewport.disable_3d = true
	camera_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(camera_viewport)

	camera_surface = TextureRect.new()
	camera_surface.name = "CameraSurface"
	camera_surface.offset_right = 40.0
	camera_surface.offset_bottom = 40.0
	camera_viewport.add_child(camera_surface)

func _start() -> void:
	if not await _request_camera_permissions():
		return
	await _start_camera()

func _request_camera_permissions() -> bool:
	if not OS.has_feature("android"):
		return true
	OS.request_permissions()
	await get_tree().on_request_permissions_result
	if not _has_camera_permission():
		status_changed.emit("Camera permission denied!")
		return false
	return true

func _has_camera_permission() -> bool:
	return "android.permission.CAMERA" in OS.get_granted_permissions()

func _get_front_camera_feed() -> CameraFeed:
	var num_cameras := CameraServer.get_feed_count()
	if num_cameras == 0:
		status_changed.emit("No camera connected!")
		return null

	for i in range(num_cameras):
		var feed := CameraServer.get_feed(i)
		if feed.get_position() == CameraFeed.FEED_FRONT:
			print("Front camera found at index: ", i)
			return feed

	status_changed.emit("No front camera found!")
	return null

func _start_camera() -> void:
	status_changed.emit("Searching for webcams...")
	CameraServer.monitoring_feeds = true
	await _wait_for_feeds()
	camera_feed = _select_camera_feed()

	if camera_feed == null:
		return

	status_changed.emit("Opening '%s'..." % camera_feed.get_name())
	camera_feed.format_changed.connect(self._camera_format_changed, ConnectFlags.CONNECT_DEFERRED)
	camera_feed.frame_changed.connect(self._camera_frame_changed, ConnectFlags.CONNECT_DEFERRED)

	var formats := camera_feed.get_formats()
	var best_format_idx := _argmax_camera_format(formats)
	print("using format %s" % formats[best_format_idx])
	camera_feed.set_format(best_format_idx, {})
	camera_feed.feed_is_active = true

func _wait_for_feeds() -> void:
	if not OS.has_feature("android"):
		await CameraServer.camera_feeds_updated
	else:
		await get_tree().create_timer(0.2).timeout

func _select_camera_feed() -> CameraFeed:
	if not OS.has_feature("android"):
		return CameraServer.get_feed(0)
	return _get_front_camera_feed()

func _fps_from_format(format: Dictionary) -> int:
	if format.has("frame_numerator") and format.has("frame_denominator"):
		return round(format["frame_denominator"] / format["frame_numerator"])
	if format.has("framerate_numerator") and format.has("framerate_denominator"):
		return round(format["framerate_numerator"] / format["framerate_denominator"])
	return -1

func _resolution_distance_from_target(format: Dictionary) -> int:
	return abs(format.width - TARGET_CAMERA_SIZE.x) + abs(format.height - TARGET_CAMERA_SIZE.y)

func _compare_formats(a: Dictionary, b: Dictionary) -> bool:
	var format_rank = FORMAT_RANKING.get(a.format, 0) - FORMAT_RANKING.get(b.format, 0)
	if format_rank != 0:
		return format_rank > 0
	var frame_rank := _fps_from_format(a) - _fps_from_format(b)
	if frame_rank != 0:
		return frame_rank > 0
	var resolution_rank := _resolution_distance_from_target(b) - _resolution_distance_from_target(a)
	if resolution_rank != 0:
		return resolution_rank > 0
	var area_rank = a.width * a.height - b.width * b.height
	if area_rank != 0:
		return area_rank < 0
	return false

func _argmax_camera_format(formats: Array) -> int:
	var best_format_idx := 0
	var best_format: Dictionary = formats[0]
	for i in range(1, formats.size()):
		var format: Dictionary = formats[i]
		if _compare_formats(format, best_format):
			best_format = format
			best_format_idx = i
	return best_format_idx

func _create_camera_texture(which_feed: CameraServer.FeedImage) -> CameraTexture:
	var texture := CameraTexture.new()
	texture.camera_feed_id = camera_feed.get_id()
	texture.which_feed = which_feed
	return texture

func _create_ycbcr_material(cbcr_texture: CameraTexture) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ycbcr_shader
	material.set_shader_parameter("cbcr_texture", cbcr_texture)
	return material

func _camera_format_changed() -> void:
	if camera_feed == null:
		return
	var datatype := camera_feed.get_datatype()
	print("camera format changed to %s" % datatype)

	var frame_size := Vector2i.ZERO
	var is_android_front_camera := OS.has_feature("android") and camera_feed.get_position() == CameraFeed.FEED_FRONT
	camera_surface.flip_h = is_android_front_camera

	if datatype == CameraFeed.FEED_RGB:
		var texture_rgb := _create_camera_texture(CameraServer.FEED_RGBA_IMAGE)
		camera_surface.material = null
		camera_surface.texture = texture_rgb
		camera_surface.flip_v = false
		frame_size = texture_rgb.get_size()
	elif datatype == CameraFeed.FEED_YCBCR_SEP:
		var texture_y := _create_camera_texture(CameraServer.FEED_Y_IMAGE)
		var texture_cbcr := _create_camera_texture(CameraServer.FEED_CBCR_IMAGE)
		camera_surface.material = _create_ycbcr_material(texture_cbcr)
		camera_surface.texture = texture_y
		camera_surface.flip_v = OS.has_feature("android")
		frame_size = texture_y.get_size()
	else:
		push_error("unsupported camera feed datatype: %s" % datatype)
		return

	var feed_rotation: float = camera_feed.feed_transform.get_rotation()
	if camera_surface.flip_h:
		feed_rotation *= -1
	var size_rotated := Vector2(frame_size).rotated(feed_rotation)
	var offset := Vector2(min(size_rotated.x, 0), min(size_rotated.y, 0))
	camera_surface.rotation = feed_rotation
	camera_surface.position = offset * -1
	camera_viewport.size = frame_size

func _camera_frame_changed() -> void:
	await RenderingServer.frame_post_draw
	var texture := camera_viewport.get_texture()
	if texture == null:
		return
	var image := texture.get_image()
	image.convert(Image.FORMAT_RGB8)
	frame_ready.emit(image)

func get_preview_texture() -> Texture2D:
	if camera_viewport == null:
		return null
	return camera_viewport.get_texture()
