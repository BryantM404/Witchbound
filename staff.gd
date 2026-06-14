extends Area3D

@export var artefact_index : int = 0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):

	if body.name == "Player":

		body.tambah_staff()

		var tracker = get_tree().get_first_node_in_group("tracker")

		if tracker:
			tracker.set_artefact_state(
				artefact_index,
				tracker.ArtefactState.REAL
			)

		queue_free()
