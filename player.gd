extends CharacterBody3D

# Menentukan kecepatan jalan karakter Barbarian
@export var SPEED: float = 5.0

# --- FITUR ANTI-KONTROL TERBALIK ---
# Jika dicentang, arah pergerakan akan disesuaikan dengan sudut pandang kamera aktif
@export var pergerakan_relatif_kamera: bool = false

# AKTIFKAN INI JIKA GERAKAN TERASA TERBALIK/BERLAWANAN!
# Cukup centang di Inspector untuk membalikkan arah instan
@export var balikkan_kanan_kiri: bool = false
@export var balikkan_maju_mundur: bool = false

# --- FITUR KOREKSI ARAH HADAP KARAKTER ---
# Isi:
# 0   = normal
# 180 = karakter berjalan mundur
# 90  = karakter berjalan menyamping kanan
# -90 = karakter berjalan menyamping kiri
@export var koreksi_arah_hadap: float = 180

# Efek gravitasi
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Referensi AnimationPlayer
@onready var anim_player: AnimationPlayer = $Rig_Medium_General/AnimationPlayer

func _ready() -> void:
	if anim_player:
		print("--- ANIMASI BERHASIL DISAMBUNGKAN! ---")
		print("Daftar animasi yang bisa Anda gunakan:")
		for anim_name in anim_player.get_animation_list():
			print("- ", anim_name)
	else:
		push_error("ERROR: Node AnimationPlayer tidak ditemukan di bawah Rig_Medium_General!")
	
func _physics_process(delta: float) -> void:
	
	# Gravitasi jika di udara
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Ambil input WASD / Arrow Key
	var input_dir := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	# Pembalikan arah manual
	if balikkan_kanan_kiri:
		input_dir.x = -input_dir.x

	if balikkan_maju_mundur:
		input_dir.y = -input_dir.y

	var direction := Vector3.ZERO

	# Gerak relatif terhadap kamera
	if pergerakan_relatif_kamera:
		var camera = get_viewport().get_camera_3d()

		if camera:
			var cam_forward = -camera.global_transform.basis.z
			var cam_right = camera.global_transform.basis.x

			cam_forward.y = 0
			cam_right.y = 0

			cam_forward = cam_forward.normalized()
			cam_right = cam_right.normalized()

			direction = (
				cam_right * input_dir.x +
				cam_forward * -input_dir.y
			).normalized()
	else:
		direction = Vector3(
			-input_dir.x,
			0,
			-input_dir.y
		).normalized()
	
	# Proses pergerakan
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Rotasi karakter menghadap arah gerak
		var target_rotation = (
			atan2(-direction.x, -direction.z)
			+ deg_to_rad(koreksi_arah_hadap)
		)

		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			15.0 * delta
		)

		# Animasi berjalan
		if anim_player:
			if anim_player.has_animation("Rig_Medium_MovementBasic/Walking_A"):
				anim_player.play("Rig_Medium_MovementBasic/Walking_A")
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
