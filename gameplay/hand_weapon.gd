extends Node

class_name HandWeapon

const BULLET_SCENE: PackedScene = preload("res://bullet/bullet.tscn")

@export var hands_view_path: NodePath
@export var bullet_audio_path: NodePath

@onready var hands_view: HandsView = get_node_or_null(hands_view_path) as HandsView
@onready var bullet_audio: AudioStreamPlayer = get_node_or_null(bullet_audio_path) as AudioStreamPlayer

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_SPACE:
		_shoot()

func _shoot() -> void:
	if hands_view == null:
		return
	var source_hand := hands_view.get_primary_hand()
	if source_hand == null:
		return

	var index_tip := source_hand.get_landmark_global_position(8)
	var index_prev := source_hand.get_landmark_global_position(7)
	var direction := (index_tip - index_prev).normalized()
	direction.z = 0
	if direction.length() == 0:
		return

	var bullet := BULLET_SCENE.instantiate() as Bullet
	bullet.direction = direction
	bullet.global_position = index_tip + direction
	get_tree().current_scene.add_child(bullet)
	bullet.look_at(bullet.global_position + direction, Vector3.UP)

	if bullet_audio != null:
		bullet_audio.pitch_scale = randf_range(0.95, 1.05)
		bullet_audio.play()
