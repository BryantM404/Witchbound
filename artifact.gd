extends Area3D

# Bisa kamu centang/matikan lewat Inspector untuk membedakan asli atau palsu
@export var is_real: bool = true 

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		if is_real:
			print("--- KAMU MENEMUKAN ARTEFAK ASLI! ---")
			if body.has_method("tambah_artefak_asli"):
				body.tambah_artefak_asli()
		else:
			print("--- ZONK! INI ARTEFAK REPLIKA/PALSU! ---")
			if body.has_method("pemicu_jebakan"):
				body.pemicu_jebakan()
		queue_free()
		
		
	
