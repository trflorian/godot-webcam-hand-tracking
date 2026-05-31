extends Node3D

@onready var camera_rig: CameraRig = $CameraRig
@onready var hand_tracker: HandTracker = $HandTracker
@onready var hands_view: HandsView = $HandsView

func _ready() -> void:
	camera_rig.frame_ready.connect(hand_tracker.process_frame)
	hand_tracker.hands_updated.connect(hands_view.update_hands)
	hand_tracker.hands_visible_changed.connect(_on_hands_visible_changed)
	hand_tracker.status_changed.connect(camera_rig.set_status_text)

func _on_hands_visible_changed(has_hands: bool) -> void:
	camera_rig.set_preview_visible(not has_hands)
