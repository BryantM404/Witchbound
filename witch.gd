extends Node3D

@export var player_path : NodePath

@onready var label = $Label3D

var player
var player_dekat = false

func _ready():

	player = get_node(player_path)

	label.visible = false

func _process(_delta):
	#if player_dekat:
		#print("PLAYER DEKAT")

	if !player_dekat:
		return

	if Input.is_action_just_pressed("interact"):
		print("INTERACT DITEKAN")
		if player.jumlah_staff_terkumpul >= 5:
			label.text = "Terima kasih, petualang!"
			print("PLAYER MENANG!")
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file("res://victory.tscn")

		else:

			label.text = "Kumpulkan semua Staff dahulu! (" + str(player.jumlah_staff_terkumpul) + "/5)"

			label.visible = true


func _on_area_3d_body_entered(body):
	print("Masuk:", body.name)

	if body == player:
		player_dekat = true
		label.text = "Tekan F untuk berbicara"
		label.visible = true


func _on_area_3d_body_exited(body):

	if body == player:

		player_dekat = false

		label.visible = false
