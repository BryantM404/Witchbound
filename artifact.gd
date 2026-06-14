extends Area3D

@export var is_real: bool = true
@export var artefact_index: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		if is_real:
			print("--- KAMU MENEMUKAN ARTEFAK ASLI! ---")
			#if body.has_method("tambah_artefak_asli"):
				#body.tambah_artefak_asli()
			
			body.tambah_artefak_asli()

			var tracker = get_tree().get_first_node_in_group("tracker")

			if tracker:
				tracker.set_artefact_state(
					artefact_index,
					tracker.ArtefactState.REAL
				)

			#queue_free()
		else:
			print("--- ZONK! INI ARTEFAK REPLIKA/PALSU! ---")
			#if body.has_method("pemicu_jebakan"):
				#body.pemicu_jebakan()
			
			var tracker = get_tree().get_first_node_in_group("tracker")

			if tracker:
				tracker.set_artefact_state(
					artefact_index,
					tracker.ArtefactState.FAKE
				)

			#queue_free()
		queue_free()
		
		
	
