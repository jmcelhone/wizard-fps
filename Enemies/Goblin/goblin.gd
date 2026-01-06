extends CharacterBody3D

@onready var hurtbox: Area3D = $Hurtbox
@onready var animation_player: AnimationPlayer = $Mesh/AnimationPlayer

func _ready() -> void:
	hurtbox.connect("area_entered", damage)
	animation_player.play("Walk")

func _physics_process(delta: float) -> void:
	velocity.y -= 12.0 * delta
	velocity.z += 1.0 * delta
	move_and_slide()

func damage(area):
	if area.name == "Hitbox":
		queue_free()
