extends RigidBody3D

func _ready() -> void:
	body_entered.connect(_on_hit)
	
	visible = false
	await get_tree().create_timer(5).timeout
	visible = true

func _process(_delta: float) -> void:
	# respawn box if below ground
	if abs(global_position.y) > 30 or abs(global_position.x) > 40:
		global_position = Vector3(0, 15, 0)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func _on_hit(body: Node) -> void:
	$AudioStreamPlayer.pitch_scale = randf_range(0.95, 1.05)
	$AudioStreamPlayer.play()
