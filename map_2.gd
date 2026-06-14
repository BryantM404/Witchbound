extends Node3D

@onready var anim_player = $Transition/AnimationPlayer

func _ready():

	anim_player.play("FadeIn")
