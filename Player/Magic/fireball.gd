extends RigidBody3D

@onready var death_timer: Timer = $DeathTimer
@onready var particle_timer: Timer = $ParticleTimer
@onready var sound: AudioStreamPlayer3D = $Sound
@onready var pre_sound: AudioStreamPlayer = $"Pre-Sound"
@onready var red_particles: GPUParticles3D = $Particles/RedParticles
@onready var smoke_particles: GPUParticles3D = $Particles/SmokeParticles
@onready var orange_particles: GPUParticles3D = $Particles/OrangeParticles

var direction: Vector3
@export var speed: float = 70.0

func _ready() -> void:
	sound.pitch_scale = randf_range(0.4, 0.7)
	pre_sound.pitch_scale = randf_range(0.8, 1.0)
	sound.play()
	pre_sound.play()
	death_timer.connect("timeout", queue_free)
	particle_timer.connect("timeout", start_particles)
	linear_velocity += -transform.basis.z * speed
	
func start_particles() -> void:
	red_particles.emitting = true
	orange_particles.emitting = true
	smoke_particles.emitting = true
