extends Control

var story = [
	"Dengan keberanian dan ketekunannya, Alaric berhasil menemukan kelima tongkat tersebut dan menyatukan kekuatannya.",
	"Saat kelima tongkat bersatu, segel sihir yang mengurung Morgana pun hancur.",
	"Sang putri akhirnya bebas dari penjara bawah tanah."
]

@onready var label = $Label
@onready var btn_play_again = $BtnPlayAgain

func _ready():
	# Di awal, sembunyikan tombol Play Again
	btn_play_again.hide() 
	play_story()

func play_story():
	for text in story:
		label.text = text
		label.visible_ratio = 0.0 
		
		var durasi_ngetik = text.length() * 0.05
		var tween = get_tree().create_tween()
		tween.tween_property(label, "visible_ratio", 1.0, durasi_ngetik)
		
		await tween.finished
		# Jeda agar pemain bisa baca kalimat terakhir
		await get_tree().create_timer(3.0).timeout

	# --- INI BAGIAN YANG KAMU MAU ---
	label.hide() # Teks ceritanya hilang dulu
	await get_tree().create_timer(0.5).timeout # Jeda sebentar biar nggak kaget
	btn_play_again.show() # Baru tombol Play Again muncul di layar yang bersih

# Fungsi saat tombol Play Again ditekan
func _on_btn_play_again_pressed():
	get_tree().change_scene_to_file("res://Opening.tscn")
