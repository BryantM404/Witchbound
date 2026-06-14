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

# Status attack, hidup, & spawn
var is_attacking := false
var is_dead := false 
var is_spawning := false # BARU: Mengunci pergerakan selama proses spawn awal/respawn

# Gaya warna dinamis untuk Bar HP Player
var sb_style: StyleBoxFlat = null

# Referensi Node Animasi & Senjata
@onready var anim_player: AnimationPlayer = $Rig_Medium_General/AnimationPlayer
@onready var sword_area: Area3D = $Rig_Medium_General/Rig_Medium/Skeleton3D/Tangan_Kanan/sword_rare_gltf/sword_rare/SwordArea

# Referensi UI Label & Bar
@onready var player_hp_label: Label = $"../GameUI/PlayerHPLabel"
@onready var enemy_hp_label: Label = $"../GameUI/EnemyHPLabel"
@onready var player_hp_bar: ProgressBar = $"../GameUI/PlayerHPBar"

func _ready() -> void:
	current_hp = MAX_HP
	is_dead = false 
	
	# Inisialisasi awal nilai dan gaya warna ProgressBar Player
	if player_hp_bar:
		player_hp_bar.max_value = MAX_HP
		player_hp_bar.value = current_hp
		player_hp_bar.visible = true # Pastikan HP Bar muncul kembali setelah restart
		
		if player_hp_bar.has_theme_stylebox_override("fill"):
			sb_style = player_hp_bar.get_theme_stylebox_override("fill").duplicate()
		else:
			sb_style = StyleBoxFlat.new()
			
		player_hp_bar.add_theme_stylebox_override("fill", sb_style)
		sb_style.bg_color = Color.GREEN 
		
	update_ui()
	
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)
		
		# --- BARU: TRIGGER ANIMASI SPAWN SAAT BARU LAHIR / RESTART ---
		if anim_player.has_animation("Spawn_Air"):
			is_spawning = true
			anim_player.play("Spawn_Air")

	# Menghubungkan sinyal deteksi pukulan pedang
	if sword_area:
		sword_area.body_entered.connect(_on_sword_area_body_entered)
		sword_area.monitoring = false

func _input(event):
	# Mencegah serangan jika sedang menyerang, mati, ATAU dalam proses spawn
	if event.is_action_pressed("attack") and !is_attacking and !is_dead and !is_spawning:
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
			
	# --- BARU: SELESAI PROSES SPAWN, PLAYER SEKARANG BISA DIKONTROL ---
	elif anim_name == "Spawn_Air":
		is_spawning = false
		print("Spawn selesai, player siap bergerak!")
			
	# RESTART GAME OTOMATIS SAAT ANIMASI MATI SELESAI
	elif anim_name == "Death_A" or anim_name == "Death":
		print("Animasi kematian selesai, merestart game...")
		get_tree().reload_current_scene() 

func take_damage(amount: float):
	if is_dead or is_spawning: return # Kebal dari damage saat sedang proses spawn awal
	
	current_hp -= amount
	update_ui()
	
	if current_hp <= 0:
		die()
	else:
		if anim_player and anim_player.has_animation("Hit_A"):
			is_attacking = false
			if sword_area: 
				sword_area.monitoring = false
			anim_player.play("Hit_A")

func update_ui():
	if player_hp_label:
		player_hp_label.text = "Player HP: " + str(current_hp)
		
	if player_hp_bar:
		player_hp_bar.value = current_hp
		
		if sb_style:
			if current_hp <= 14.0:
				sb_style.bg_color = Color.RED       
			elif current_hp <= 49.0:
				sb_style.bg_color = Color.ORANGE    
			else:
				sb_style.bg_color = Color.GREEN     

func die():
	if is_dead: return
	
	is_dead = true 
	
	if player_hp_label:
		player_hp_label.text = "PLAYER DIED! GAME OVER"
	print("Player Mati!")
	
	if player_hp_bar:
		player_hp_bar.visible = false
		
	if anim_player:
		if anim_player.has_animation("Death_A"):
			anim_player.play("Death_A")
		elif anim_player.has_animation("Death"):
			anim_player.play("Death")

	# Menghentikan program loop fisik karakter (Karakter diam membeku total)
	set_physics_process(false)
	is_attacking = true
	if sword_area:
		sword_area.monitoring = false

func _physics_process(delta: float) -> void:
	# Jika sudah mati, kunci pergerakan total
	if is_dead:
		return

	# --- BARU: Kunci pergerakan dan biarkan jatuh secara fisik selama animasi Spawn ---
	if is_spawning:
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Saat attack, karakter tidak bisa bergerak
	if is_attacking:
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Gravitasi jika di udara biasa
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- 1. LOGIKA ROTASI (Kanan/Kiri) ---
	if Input.is_action_pressed("ui_left"):
		rotation.y += 3.0 * delta 

	if Input.is_action_pressed("ui_right"):
		rotation.y -= 3.0 * delta 

	# --- 2. LOGIKA MAJU MUNDUR ---
	var move_input := 0.0

	if Input.is_action_pressed("ui_up"):
		move_input = -1.0 

	if Input.is_action_pressed("ui_down"):
		move_input = 1.0  

	var forward = -transform.basis.z

	velocity.x = forward.x * move_input * SPEED
	velocity.z = forward.z * move_input * SPEED

	if move_input != 0:
		if anim_player:
			if anim_player.has_animation("Walking_A_Manual"): anim_player.play("Walking_A_Manual")
			elif anim_player.has_animation("Rig_Medium_MovementBasic/Running_A"): anim_player.play("Rig_Medium_MovementBasic/Running_A")
			elif anim_player.has_animation("Walking"): anim_player.play("Walking")
			elif anim_player.has_animation("walk"): anim_player.play("walk")
			elif anim_player.has_animation("Walk"): anim_player.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		if anim_player:
			if anim_player.has_animation("Idle_A"): anim_player.play("Idle_A")
			elif anim_player.has_animation("Idle"): anim_player.play("Idle")
			elif anim_player.has_animation("idle"): anim_player.play("idle")

	move_and_slide()

func _on_sword_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(25) 
		
		if enemy_hp_label:
			if body.current_hp > 0:
				enemy_hp_label.text = "Enemy HP: " + str(body.current_hp) + " / " + str(body.MAX_HP)
			else:
				enemy_hp_label.text = "Enemy Killed!"
				
# Tambahkan ini di bagian atas bersama variabel lainnya
var jumlah_artefak_terkumpul: int = 0
var jumlah_staff_terkumpul : int = 0

# Tambahkan fungsi baru ini di bagian paling bawah script player
func tambah_artefak_asli():
	jumlah_artefak_terkumpul += 1
	print("Artefak asli dibawa: ", jumlah_artefak_terkumpul)
	# Di sini kamu bisa update teks UI kelompokmu, misal: "Artefak: 1/2"

func tambah_staff():

	jumlah_staff_terkumpul += 1

	print(
		"Staff terkumpul: ",
		jumlah_staff_terkumpul,
		"/5"
	)

func pemicu_jebakan():
	# Contoh efek zonk: mengurangi darah player karena barang palsu beracun/meledak
	if has_method("take_damage"):
		take_damage(15) # Mengurangi 15 HP player karena tertipu barang palsu
