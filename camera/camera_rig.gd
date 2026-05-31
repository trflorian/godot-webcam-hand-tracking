extends Node3D

class_name CameraRig

signal frame_ready(image: Image)

@onready var camera_source: CameraSource = $CameraSource
@onready var camera_preview: CameraPreview = $CameraPreview

func _ready() -> void:
	camera_source.frame_ready.connect(_on_frame_ready)
	camera_source.status_changed.connect(camera_preview.set_status)

func _on_frame_ready(image: Image) -> void:
	camera_preview.mark_frame_available()
	frame_ready.emit(image)

func set_preview_visible(visible_now: bool) -> void:
	camera_preview.set_preview_visible(visible_now)

func set_status_text(text: String) -> void:
	camera_preview.set_status(text)
