extends Node3D

@export var player_path: NodePath

@onready var artefak = $artifact_gltf
@onready var label_info = $Label3D
var anim_player

var player
var player_dekat = false
var artefak_ditaruh = false


func _ready():
	player = get_node(player_path)

	anim_player = get_tree().current_scene.get_node("Transition/AnimationPlayer")

	print(anim_player)

	artefak.visible = false
	label_info.visible = false


func _process(_delta):

	if !player_dekat:
		return

	if Input.is_action_just_pressed("interact"):

		if artefak_ditaruh:
			return

		if player.jumlah_artefak_terkumpul > 0:

			player.jumlah_artefak_terkumpul -= 1

			artefak.visible = true
			label_info.visible = false

			artefak_ditaruh = true

			print("Artefak berhasil ditempatkan!")
			
			anim_player.play("FadeOut")

			await anim_player.animation_finished

			get_tree().change_scene_to_file("res://perjalanan.tscn")

		else:

			label_info.text = "Artefak asli belum ditemukan!"
			label_info.visible = true


func _on_area_3d_body_entered(body):

	if body == player:
		player_dekat = true


func _on_area_3d_body_exited(body):

	if body == player:
		player_dekat = false
		label_info.visible = false
