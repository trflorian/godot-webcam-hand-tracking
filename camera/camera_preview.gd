extends CanvasLayer

class_name CameraPreview

@onready var camera_view: TextureRect = $CameraView
@onready var camera_status: Label = $CameraStatus

var _is_preview_visible: bool = false
var _has_frame: bool = false

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
