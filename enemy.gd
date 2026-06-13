extends CharacterBody3D

@export var SPEED = 2.0
@export var is_boss: bool = false
@export var MAX_CHASE_DISTANCE: float = 12.0

var max_hp: float = 30.0
var current_hp: float = max_hp
var damage_power: float = 10.0

var player: CharacterBody3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var home_position: Vector3
var is_enemy_attacking: bool = false

# --- REFERENSI NODE ASET BARU ---
@onready var anim_player: AnimationPlayer = $Model_Musuh_Aset/AnimationPlayer # Sesuaikan path ke AnimationPlayer aset musuh
@onready var enemy_sword_area: Area3D = $Model_Musuh_Aset/BoneAttachment3D/Aset_Senjata_Musuh/EnemySwordArea # Sesuaikan path-nya

func _ready():
	home_position = global_position
	
	if is_boss:
		max_hp = 100.0
		damage_power = 20.0
		MAX_CHASE_DISTANCE = 18.0
	else:
		max_hp = 30.0
		damage_power = 5.0
		
	current_hp = max_hp
	
	# Sambungkan deteksi area senjata musuh ke player
	if enemy_sword_area:
		enemy_sword_area.body_entered.connect(_on_enemy_sword_hit)
		enemy_sword_area.monitoring = false
		
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jika musuh sedang dalam animasi memukul, dia diam di tempat
	if is_enemy_attacking:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	var distance_from_home = global_position.distance_to(home_position)

	if player and distance_from_home < MAX_CHASE_DISTANCE:
		# --- LOGIKA KEJAR ---
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
		# Mainkan animasi jalan musuh
		if anim_player and anim_player.has_animation("Walking"):
			anim_player.play("Walking")
		
		# Jarak serang fisik (jika dekat dengan player, musuh akan memukul)
		if global_position.distance_to(player.global_position) < 1.8:
			start_enemy_attack()
	else:
		# --- LOGIKA PULANG ---
		var distance_to_home = global_position.distance_to(home_position)
		if distance_to_home > 0.5:
			var direction = (home_position - global_position).normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			look_at(Vector3(home_position.x, global_position.y, home_position.z), Vector3.UP)
			if anim_player and anim_player.has_animation("Walking"):
				anim_player.play("Walking")
		else:
			# Diam di rumah
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			if anim_player and anim_player.has_animation("Idle"):
				anim_player.play("Idle")

	move_and_slide()

func start_enemy_attack():
	if is_enemy_attacking: return
	
	is_enemy_attacking = true
	
	# Nyalakan area hit pedang musuh
	if enemy_sword_area:
		enemy_sword_area.monitoring = true
		
	# Jalankan animasi menyerang milik aset musuh (Ganti "Attack" sesuai nama animasi di asetmu)
	if anim_player and anim_player.has_animation("Attack"):
		anim_player.play("Attack")

func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		is_enemy_attacking = false
		# Matikan deteksi setelah tebasan selesai
		if enemy_sword_area:
			enemy_sword_area.monitoring = false

func _on_enemy_sword_hit(body: Node3D):
	# Jika senjata musuh mengenai Player, kurangi darah Player
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(damage_power)

func take_damage(amount: float):
	current_hp -= amount
	print("Darah musuh berkurang! Sisa: ", current_hp)
	
	if current_hp <= 0:
		if player and player.enemy_hp_label:
			player.enemy_hp_label.text = "Enemy HP: Dead!"
		queue_free()

# Pemicu saat Player masuk area deteksi silinder besar
func _on_detection_area_body_entered(body):
	if body.name == "Player":
		player = body

# Pemicu saat Player lari keluar dari area silinder besar
func _on_detection_area_body_exited(body):
	if body.name == "Player":
		player = null


func _on_detection_area_area_exited(area: Area3D) -> void:
	pass # Replace with function body.
