extends CharacterBody3D

# Menentukan kecepatan jalan karakter Barbarian
@export var SPEED: float = 5.0

# --- FITUR ANTI-KONTROL TERBALIK ---
@export var pergerakan_relatif_kamera: bool = false
@export var balikkan_kanan_kiri: bool = false
@export var balikkan_maju_mundur: bool = false

# --- FITUR KOREKSI ARAH HADAP KARAKTER ---
@export var koreksi_arah_hadap: float = 180

# Efek gravitasi
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Status attack
var is_attacking := false

# Referensi AnimationPlayer
@onready var anim_player: AnimationPlayer = $Rig_Medium_General/AnimationPlayer


func _ready() -> void:
	if anim_player:
		print("--- ANIMASI BERHASIL DISAMBUNGKAN! ---")
		print("Daftar animasi yang bisa Anda gunakan:")

		for anim_name in anim_player.get_animation_list():
			print("- ", anim_name)

		anim_player.animation_finished.connect(_on_animation_finished)
	else:
		push_error("ERROR: Node AnimationPlayer tidak ditemukan di bawah Rig_Medium_General!")


func _input(event):
	if event.is_action_pressed("attack") and !is_attacking:
		start_attack()


func start_attack():
	if anim_player and anim_player.has_animation("Throw"):
		is_attacking = true
		anim_player.speed_scale = 2
		anim_player.play("Throw")


func _on_animation_finished(anim_name):
	if anim_name == "Throw":
		is_attacking = false
		anim_player.speed_scale = 1.0


func _physics_process(delta: float) -> void:

	# Saat attack, karakter tidak bisa bergerak
	if is_attacking:
		velocity.x = 0
		velocity.z = 0

		if not is_on_floor():
			velocity.y -= gravity * delta

		move_and_slide()
		return

	# Gravitasi jika di udara
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Putar karakter
	if Input.is_action_pressed("ui_left"):
		rotation.y += 3.0 * delta

	if Input.is_action_pressed("ui_right"):
		rotation.y -= 3.0 * delta

	# Maju mundur
	var move_input := 0.0

	if Input.is_action_pressed("ui_up"):
		move_input = -1.0

	if Input.is_action_pressed("ui_down"):
		move_input = 1.0

	# Arah depan karakter
	var forward = -transform.basis.z

	velocity.x = forward.x * move_input * SPEED
	velocity.z = forward.z * move_input * SPEED

	# Proses pergerakan
	if move_input != 0:

		# Animasi berjalan
		if anim_player:

			if anim_player.has_animation("Walking_A_Manual"):
				anim_player.play("Walking_A_Manual")

			elif anim_player.has_animation("Rig_Medium_MovementBasic/Running_A"):
				anim_player.play("Rig_Medium_MovementBasic/Running_A")

			elif anim_player.has_animation("Walking"):
				anim_player.play("Walking")

			elif anim_player.has_animation("walk"):
				anim_player.play("walk")

			elif anim_player.has_animation("Walk"):
				anim_player.play("Walk")

	else:

		# Perlambatan saat berhenti
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		# Animasi idle
		if anim_player:

			if anim_player.has_animation("Idle_A"):
				anim_player.play("Idle_A")

			elif anim_player.has_animation("Idle"):
				anim_player.play("Idle")

			elif anim_player.has_animation("idle"):
				anim_player.play("idle")

	move_and_slide()
