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

@onready var attack_area: Area3D = $AttackArea

# Referensi timer biar musuh ga ngasih damage tiap frame (bisa bikin player langsung mati instan)
var attack_cooldown: float = 0.0

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
	attack_area.body_entered.connect(_on_player_entered)
	attack_area.body_exited.connect(_on_player_exited)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Mengatur jeda waktu serang musuh
	if attack_cooldown > 0:
		attack_cooldown -= delta

	var distance_from_home = global_position.distance_to(home_position)

	if player and distance_from_home < MAX_CHASE_DISTANCE:
		# KEJAR
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
		# Logika memberikan damage ke player jika sudah sangat dekat (jarak pukul)
		if global_position.distance_to(player.global_position) < 1.5 and attack_cooldown <= 0:
			if player.has_method("take_damage"):
				player.take_damage(damage_power)
				attack_cooldown = 1.0 # Musuh hanya bisa mukul 1 detik sekali
	else:
		# PULANG
		var distance_to_home = global_position.distance_to(home_position)
		if distance_to_home > 0.5:
			var direction = (home_position - global_position).normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			look_at(Vector3(home_position.x, global_position.y, home_position.z), Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _on_player_entered(body):
	if body.name == "Player":
		player = body

func _on_player_exited(body):
	if body.name == "Player":
		player = null

# Fungsi ketika musuh menerima sabetan pedang player
func take_damage(amount: float):
	current_hp -= amount
	print("Darah musuh berkurang! Sisa: ", current_hp)
	
	if current_hp <= 0:
		# Sebelum musuh hilang, hapus teks info darah musuh di UI atas
		if player and player.enemy_hp_label:
			player.enemy_hp_label.text = "Enemy HP: Dead!"
		queue_free()
