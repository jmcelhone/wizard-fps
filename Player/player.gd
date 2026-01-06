extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var projectile_marker: Marker3D = $Head/Camera3D/ProjectileMarker
@onready var jump_land_sound: AudioStreamPlayer = $SFX/JumpLandSound
@onready var jump_sound: AudioStreamPlayer = $SFX/JumpSound
@onready var step_sound: AudioStreamPlayer = $SFX/StepSound
@onready var levitation_cast_sound: AudioStreamPlayer = $SFX/LevitationCastSound
@onready var levitation_sound: AudioStreamPlayer = $SFX/LevitationSound
@onready var fireball_timer: Timer = $FireballTimer
@onready var staff_animator: AnimationPlayer = $Head/Staff/AnimationPlayer


@export var Fireball: PackedScene

var walk_speed: float = 10.0
var run_speed: float = 20.0
var jump_velocity: float = 7.0
var recoil_multiplier: float = 10.0
var speed: float = walk_speed
var gravity: float = 12.0
var can_levitate: bool = false
var max_levitation_amount: float = 10.0
var levitation_amount: float = max_levitation_amount
var levitation_velocity: float = 10.0
const SENSITIVITY = 0.010

enum State { IDLE, WALKING, RUNNING, FALLING, LEVITATING }

var current_state: State = State.IDLE

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera_3d.rotate_x(-event.relative.y * SENSITIVITY)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-70), deg_to_rad(70))

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		shoot()
	update_state()
	process_state(delta)
	move_and_slide()

func update_state() -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var new_state: State
	
	if current_state != State.LEVITATING:
		if camera_3d.fov > 75.0:
			camera_3d.fov -= 1.0
	if current_state == State.FALLING and is_on_floor():
		can_levitate = false
		levitation_amount = max_levitation_amount
		jump_land_sound.play()
	if not is_on_floor():
		if Input.is_action_pressed("jump") and levitation_amount > 0 and can_levitate:
			new_state = State.LEVITATING
		else:
			new_state = State.FALLING
	elif input_direction.length() > 0:
		new_state = State.RUNNING if Input.is_action_pressed("run") else State.WALKING
	else:
		new_state = State.IDLE
	
	if new_state != current_state:
		transition_to(new_state)

func transition_to(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.IDLE:
			if velocity == Vector3.ZERO:
				step_sound.stop()
		State.WALKING:
			step_sound.pitch_scale = randf_range(0.8, 1.2)
			speed = walk_speed
		State.RUNNING:
			step_sound.pitch_scale = randf_range(1.2, 1.5)
			speed = run_speed
		State.FALLING:
			levitation_sound.stop()
			step_sound.stop()
		State.LEVITATING:
			levitation_sound.pitch_scale = randf_range(1.5, 2.0)
			levitation_cast_sound.play()

func process_state(delta: float) -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	match current_state:
		State.IDLE:
			if Input.is_action_just_pressed("jump"): jump()
			velocity.x = lerp(velocity.x, 0.0, delta * 3.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 3.0)
		
		State.WALKING, State.RUNNING:
			walk(delta, direction)
			if Input.is_action_just_pressed("jump"): jump()
		State.FALLING:
			fall(delta, direction)
		State.LEVITATING:
			levitate(delta)

func walk(delta, direction):
	velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
	velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	if not step_sound.playing:
		step_sound.play()

func jump():
	if not jump_sound.playing:
		jump_sound.play()
	velocity.y = jump_velocity
	transition_to(State.FALLING)

func fall(delta, direction):
	if Input.is_action_just_released("jump"):
		can_levitate = true
	velocity.y -= gravity * delta
	velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
	velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	if is_on_floor():
		jump_land_sound.play()

func shoot():
	if fireball_timer.time_left <= 0.0:
		staff_animator.speed_scale = 3.0
		staff_animator.play("StaffAction")
		var fireball = Fireball.instantiate()
		add_child(fireball)
		fireball.red_particles.emitting = false
		fireball.orange_particles.emitting = false
		fireball.smoke_particles.emitting = false
		fireball.global_position = projectile_marker.global_position -head.position
		fireball.global_rotation = projectile_marker.global_rotation
		fireball.linear_velocity = -projectile_marker.global_transform.basis.z * fireball.speed
		velocity += projectile_marker.global_transform.basis.z * recoil_multiplier
		fireball_timer.start()

func levitate(delta):
	levitation_sound.pitch_scale += 0.005
	if camera_3d.fov < 85.0:
		camera_3d.fov += 1.0
	if not levitation_sound.playing:
		levitation_sound.play()
	levitation_amount -= 1.0 * delta
	velocity.y = levitation_velocity
