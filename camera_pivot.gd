extends Node3D

@export var player: Node3D

func _process(_delta):
	if player:
		global_position = player.global_position
