extends Node3D

@export var player: Node3D
@export var mouse_sensitivity := 0.005

var rotating := false

func _process(_delta):
	if player:
		global_position = player.global_position

func _input(event):

	# Klik kanan ditekan/dilepas
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

	# Putar kamera hanya saat klik kanan ditahan
	if rotating and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
