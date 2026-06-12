extends CharacterBody3D

@export var SPEED: float = 5.0

# --- FITUR ANTI-KONTROL TERBALIK ---
@export var pergerakan_relatif_kamera: bool = false
@export var balikkan_kanan_kiri: bool = false
@export var balikkan_maju_mundur: bool = false

# --- FITUR KOREKSI ARAH HADAP KARAKTER ---
@export var koreksi_arah_hadap: float = 180

# --- SISTEM HEALTH PLAYER ---
@export var MAX_HP: float = 100.0
var current_hp: float = MAX_HP

# Efek gravitasi
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Status attack
var is_attacking := false

# Referensi Node Animasi & Senjata
@onready var anim_player: AnimationPlayer = $Rig_Medium_General/AnimationPlayer
@onready var sword_area: Area3D = $Rig_Medium_General/BoneAttachment3D2/sword_rare_gltf/sword_rare/SwordArea

# Referensi UI Label
@onready var player_hp_label: Label = $"../GameUI/PlayerHPLabel"
@onready var enemy_hp_label: Label = $"../GameUI/EnemyHPLabel"

func _ready() -> void:
	current_hp = MAX_HP
	update_ui()
	
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)

	# Menghubungkan sinyal deteksi pukulan pedang
	if sword_area:
		sword_area.body_entered.connect(_on_sword_hit)
		sword_area.monitoring = false 

func _input(event):
	if event.is_action_pressed("attack") and !is_attacking:
		start_attack()

func start_attack():
	if anim_player and anim_player.has_animation("Throw"): 
		is_attacking = true
		anim_player.speed_scale = 2.0
		anim_player.play("Throw")
		
		if sword_area:
			sword_area.monitoring = true

func _on_animation_finished(anim_name):
	if anim_name == "Throw":
		is_attacking = false
		anim_player.speed_scale = 1.0
		if sword_area:
			sword_area.monitoring = false

func _on_sword_hit(body: Node3D):
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(25) 
		
		if enemy_hp_label:
			enemy_hp_label.text = "Enemy HP: " + str(body.current_hp) + " / " + str(body.max_hp)

func take_damage(amount: float):
	current_hp -= amount
	update_ui()
	if current_hp <= 0:
		die()

func update_ui():
	if player_hp_label:
		player_hp_label.text = "Player HP: " + str(current_hp)

func die():
	if player_hp_label:
		player_hp_label.text = "PLAYER DIED! GAME OVER"
	print("Player Mati!")
	set_physics_process(false)

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

	# --- 1. KEMBALI KE LOGIKA ROTASI (Kanan/Kiri) ---
	if Input.is_action_pressed("ui_left"):
		rotation.y += 3.0 * delta # Berputar ke kiri

	if Input.is_action_pressed("ui_right"):
		rotation.y -= 3.0 * delta # Berputar ke kanan

	# --- 2. LOGIKA MAJU MUNDUR ---
	var move_input := 0.0

	if Input.is_action_pressed("ui_up"):
		move_input = -1.0 # Maju ke arah depan karakter

	if Input.is_action_pressed("ui_down"):
		move_input = 1.0  # Mundur ke arah belakang karakter

	# Mendapatkan arah hadapan depan karakter sesungguhnya
	var forward = -transform.basis.z

	velocity.x = forward.x * move_input * SPEED
	velocity.z = forward.z * move_input * SPEED

	# Proses pergerakan dan animasi jika ada input maju/mundur
	if move_input != 0:
		if anim_player:
			if anim_player.has_animation("Walking_A_Manual"): anim_player.play("Walking_A_Manual")
			elif anim_player.has_animation("Rig_Medium_MovementBasic/Running_A"): anim_player.play("Rig_Medium_MovementBasic/Running_A")
			elif anim_player.has_animation("Walking"): anim_player.play("Walking")
			elif anim_player.has_animation("walk"): anim_player.play("walk")
			elif anim_player.has_animation("Walk"): anim_player.play("Walk")
	else:
		# Perlambatan saat berhenti
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		if anim_player:
			if anim_player.has_animation("Idle_A"): anim_player.play("Idle_A")
			elif anim_player.has_animation("Idle"): anim_player.play("Idle")
			elif anim_player.has_animation("idle"): anim_player.play("idle")

	move_and_slide()
