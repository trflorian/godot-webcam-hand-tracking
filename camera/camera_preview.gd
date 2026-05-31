extends CanvasLayer

class_name CameraPreview

@onready var camera_view: TextureRect = $CameraView
@onready var camera_status: Label = $CameraStatus

var _is_preview_visible: bool = false
var _has_frame: bool = false

func _ready() -> void:
	var camera_source := get_node_or_null("/root/CameraSource") as CameraSource
	if camera_source != null:
		camera_source.frame_ready.connect(_on_frame_ready)
		camera_source.status_changed.connect(set_status)
		camera_view.texture = camera_source.get_preview_texture()

	var hand_tracker := get_node_or_null("/root/HandTracker") as HandTracker
	if hand_tracker != null:
		hand_tracker.hands_visible_changed.connect(_on_hands_visible_changed)

func set_status(text: String) -> void:
	camera_status.text = text

func mark_frame_available() -> void:
	if _has_frame:
		return
	_has_frame = true
	camera_status.visible = false
	camera_view.visible = true

func set_preview_visible(visible_now: bool) -> void:
	if _is_preview_visible == visible_now:
		return
	_is_preview_visible = visible_now
	var tween := get_tree().create_tween()
	var alpha := 1.0 if visible_now else 0.0
	tween.tween_property(camera_view, "modulate", Color(1, 1, 1, alpha), 0.3)
	tween.set_ease(Tween.EASE_OUT)

func _on_frame_ready(_image: Image) -> void:
	mark_frame_available()

func _on_hands_visible_changed(has_hands: bool) -> void:
	set_preview_visible(not has_hands)
