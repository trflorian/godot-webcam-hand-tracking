extends RigidBody3D

class_name Bullet

const BULLET_SPEED := 60.0

var direction: Vector3

func _ready() -> void:
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(queue_free)

func _physics_process(_delta: float) -> void:
	linear_velocity = direction * BULLET_SPEED
