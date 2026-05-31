extends Node

class_name HandWeapon

const BULLET_SCENE: PackedScene = preload("res://bullet/bullet.tscn")

@export var source_hand: HandView

@onready var bullet_audio: AudioStreamPlayer = $BulletAudio

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_SPACE:
		_shoot()

func _shoot() -> void:
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
