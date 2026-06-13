extends CharacterBody3D

@export var SPEED: float = 3.0
@export var ATTACK_RANGE: float = 2.0 # Jarak ideal musuh untuk mulai memukul

# --- SISTEM COOLDOWN SERANGAN MUSUH ---
@export var ATTACK_COOLDOWN: float = 1.5 # Jeda waktu antar pukulan (dalam detik)
var attack_cooldown_timer: float = 0.0   # Penghitung waktu mundur internal

# --- SISTEM HEALTH ENEMY (DIATUR KE 50) ---
@export var MAX_HP: float = 50.0
var current_hp: float = MAX_HP

# Efek gravitasi
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Status AI & Attack
var is_attacking := false
var is_hit := false
var is_dead := false
var player: CharacterBody3D = null

# Referensi Node Animasi & Senjata Musuh (Sudah Fixed menggunakan Kapak)
@onready var anim_player: AnimationPlayer = $Rig_Medium_General/AnimationPlayer
@onready var sword_area: Area3D = $Rig_Medium_General/Rig_Medium/Skeleton3D/BoneAttachment3D/AxeDoubleCommon/Area3D
@onready var detection_area: Area3D = $DetectionArea

# --- PERUBAHAN TARGET REFERENSI VISIBILITAS ---
# Mengarah langsung ke HPBarPivot agar seluruh komponen 3D ikut hilang sempurna
@onready var hp_progress_bar_pivot: Node3D = $HPBarPivot
@onready var hp_progress_bar: ProgressBar = $HPBarPivot/HPBarSprite/HPBarViewport/HPProgressBar

# Gaya warna dinamis untuk Bar HP
var sb_style: StyleBoxFlat = null

func _ready() -> void:
	current_hp = MAX_HP
	is_dead = false
	is_attacking = false
	is_hit = false
	
	# Memasukkan musuh ini ke dalam grup "enemy" secara otomatis
	add_to_group("enemy")
	
	# Inisialisasi awal nilai dan warna Progress Bar
	if hp_progress_bar:
		hp_progress_bar.max_value = MAX_HP
		hp_progress_bar.value = current_hp
		
		if hp_progress_bar.has_theme_stylebox_override("fill"):
			sb_style = hp_progress_bar.get_theme_stylebox_override("fill").duplicate()
		else:
			sb_style = StyleBoxFlat.new()
			
		hp_progress_bar.add_theme_stylebox_override("fill", sb_style)
		sb_style.bg_color = Color.GREEN # Set warna awal penuh: Hijau
		
	# --- HIDDEN TOTAL DI AWAL: Sembunyikan seluruh komponen Pivot 3D-nya ---
	if hp_progress_bar_pivot:
		hp_progress_bar_pivot.visible = false
	
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)

	# Menghubungkan sinyal deteksi pukulan pedang milik musuh
	if sword_area:
		sword_area.body_entered.connect(_on_sword_hit)
		sword_area.monitoring = false

	# Menghubungkan sinyal deteksi penglihatan musuh (Area3D)
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float) -> void:
	# Jika musuh mati atau sedang terkejut onscreen hit, jalankan gravitasi saja lalu return
	if is_dead or is_hit:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Gravitasi jika musuh di udara
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Logika jika sedang mengayunkan senjata (berhenti total di tempat)
	if is_attacking:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Logika AI jika mendeteksi Player di dalam radar penglihatan
	# Logika AI jika mendeteksi Player di dalam radar penglihatan
	if player:
		# --- BARU: CEK APAKAH PLAYER SUDAH MATI ---
		# Catatan: Sesuaikan "is_dead" dengan nama variabel kematian di skrip Player kamu (misal: is_dead atau current_hp <= 0)
		if player.get("is_dead") == true or player.get("current_hp") <= 0:
			player = null # Paksa musuh melupakan player
			if hp_progress_bar_pivot:
				hp_progress_bar_pivot.visible = false # Sembunyikan HP bar musuh lagi
			return # Keluar dari logika mengejar/menyerang
			
		# Jalankan hitung mundur timer cooldown jika nilainya di atas 0
		if attack_cooldown_timer > 0:
			attack_cooldown_timer -= delta

		# Hitung arah dan jarak ke player
		var direction = (player.global_position - global_position)
		direction.y = 0
		var distance = direction.length()
		direction = direction.normalized()

		# Musuh otomatis selalu berputar menghadap tajam ke arah player
		if direction != Vector3.ZERO:
			look_at(global_position + direction, Vector3.UP)

		# KONDISI DETEKSI DAN COOLDOWN:
		if distance <= ATTACK_RANGE:
			if attack_cooldown_timer <= 0:
				# Jika sudah dekat DAN waktu jeda habis, langsung pukul!
				start_attack()
			else:
				# Jika sudah dekat tapi masih dalam masa cooldown, diam bersiap
				velocity.x = 0
				velocity.z = 0
				play_idle_animation()
		else:
			# Jika player masih agak jauh di dalam radar, KEJAR menggunakan kecepatan penuh
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			play_movement_animation()
			
	move_and_slide()

# --- SISTEM SERANGAN (ATTACK) ---

func start_attack():
	if anim_player and anim_player.has_animation("Throw") and not is_attacking and not is_hit and not is_dead: 
		is_attacking = true
		anim_player.speed_scale = 1.5 # Menyesuaikan kecepatan animasi attack musuh
		anim_player.play("Throw")
		
		if sword_area:
			sword_area.monitoring = true

func _on_animation_finished(anim_name):
	if anim_name == "Throw":
		is_attacking = false
		if anim_player:
			anim_player.speed_scale = 1.0
		if sword_area:
			sword_area.monitoring = false
		
		# AKTIFKAN WAKTU JEDA SERANGAN SETELAH AYUNAN SENJATA SELESAI
		attack_cooldown_timer = ATTACK_COOLDOWN
			
	elif anim_name == "Hit_A":
		is_hit = false # Setelah animasi terkejut selesai, musuh bisa mengejar player lagi
		
	elif anim_name == "Death" or anim_name == "Rig_Medium_MovementBasic/Death":
		# Tunggu sampai animasi jatuh ke tanah selesai 100%, baru hapus dari dunia game
		queue_free()

func _on_sword_hit(body: Node3D):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(15) 

# --- SISTEM HEALTH & DAMAGE (HIT & DEATH ANIMATION) ---

func take_damage(amount: float):
	if is_dead: return # Jika sudah mati, abaikan pukulan beruntun
	
	current_hp -= 10.0
	
	# Perbarui visual dan warna Bar HP
	if hp_progress_bar:
		hp_progress_bar.value = current_hp
		if sb_style:
			if current_hp <= 12.0:
				sb_style.bg_color = Color.RED
			elif current_hp <= 25.0:
				sb_style.bg_color = Color.ORANGE
			else:
				sb_style.bg_color = Color.GREEN
				
	# Cek Kondisi Nyawa
	if current_hp <= 0:
		die()
	else:
		# Jika masih hidup, interupsi aksi musuh dan jalankan animasi terkena hit ("Hit_A")
		if anim_player and anim_player.has_animation("Hit_A"):
			is_attacking = false
			is_hit = true
			if sword_area: sword_area.monitoring = false
			anim_player.play("Hit_A")

func die():
	print("Enemy Mati!")
	is_dead = true
	is_attacking = false
	is_hit = false
	
	# Matikan area tabrakan pedang musuh agar adil bagi player
	if sword_area:
		sword_area.monitoring = false
		
	# --- HILANG TOTAL: Sembunyikan seluruh komponen Pivot saat musuh mati ---
	if hp_progress_bar_pivot:
		hp_progress_bar_pivot.visible = false

	# Putar animasi kematian sesuai dengan library model kamu
	if anim_player:
		if anim_player.has_animation("Death"):
			anim_player.play("Death")
		elif anim_player.has_animation("Rig_Medium_MovementBasic/Death"):
			anim_player.play("Rig_Medium_MovementBasic/Death")
		elif anim_player.has_animation("Die"):
			anim_player.play("Die")
		else:
			queue_free()

# --- PENGELOLA ANIMASI OTOMATIS ---

func play_movement_animation():
	if anim_player and not is_attacking and not is_hit and not is_dead:
		if anim_player.has_animation("Rig_Medium_MovementBasic/Running_A"): 
			anim_player.play("Rig_Medium_MovementBasic/Running_A")
		elif anim_player.has_animation("Walking_A_Manual"): 
			anim_player.play("Walking_A_Manual")
		elif anim_player.has_animation("Walking"): 
			anim_player.play("Walking")

func play_idle_animation():
	if anim_player and not is_attacking and not is_hit and not is_dead:
		if anim_player.has_animation("Idle_A"): anim_player.play("Idle_A")
		elif anim_player.has_animation("Idle"): anim_player.play("Idle")

# --- RESPONS SINYAL DETEKSI AREA3D ---

func _on_detection_area_body_entered(body: Node3D) -> void:
	# ANTISIPASI BUG: Abaikan jika objek yang masuk radar adalah tubuh musuh itu sendiri
	if body == self:
		return
		
	if body.is_in_group("player"): 
		player = body
		
		# --- MUNCULKAN TOTAL: Saat Player masuk jarak deteksi, aktifkan pivot 3D-nya ---
		if hp_progress_bar_pivot and not is_dead:
			hp_progress_bar_pivot.visible = true

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == self:
		return
		
	if body.is_in_group("player"): 
		# --- BARU: Hanya jadikan target jika Player masih hidup ---
		if body.get("is_dead") == false and body.get("current_hp") > 0:
			player = body
			
			# Saat Player masuk area radar mendekat, munculkan HP Bar!
			if hp_progress_bar_pivot and not is_dead:
				hp_progress_bar_pivot.visible = true
