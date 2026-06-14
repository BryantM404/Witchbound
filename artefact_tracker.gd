extends Control

enum ArtefactState {
	HIDDEN,
	FAKE,
	REAL
}

@onready var artefact_icons = [
	$HBoxContainer/Artefact1,
	$HBoxContainer/Artefact2,
	$HBoxContainer/Artefact3,
	$HBoxContainer/Artefact4,
	$HBoxContainer/Artefact5
]

func _ready():
	
	print(artefact_icons)

	# Semua artefak awalnya belum ditemukan
	for icon in artefact_icons:
		set_icon_hidden(icon)

# =====================
# FUNGSI STATUS IKON
# =====================

func set_icon_hidden(icon: TextureRect):
	# Gelap / samar
	icon.modulate = Color(1, 1, 1, 0.25)

func set_icon_fake(icon: TextureRect):
	# Abu-abu
	icon.modulate = Color(0.6, 0.6, 0.6, 1)

func set_icon_real(icon: TextureRect):
	# Warna asli gambar
	icon.modulate = Color(1, 1, 1, 1)

# =====================
# DIPANGGIL DARI SCRIPT LAIN
# =====================

func set_artefact_state(index:int, state:int):

	if index < 0 or index >= artefact_icons.size():
		return

	var icon = artefact_icons[index]

	match state:

		ArtefactState.HIDDEN:
			set_icon_hidden(icon)

		ArtefactState.FAKE:
			set_icon_fake(icon)

		ArtefactState.REAL:
			set_icon_real(icon)
