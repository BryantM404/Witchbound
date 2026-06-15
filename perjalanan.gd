extends Control

var story = [
	"Di dalam bawah tanah, Alaric menemukan bahwa kutukan Morgana hanya dapat dipatahkan...",
	"...dengan mengumpulkan 5 Tongkat Sihir Kuno yang tersebar di berbagai ruangan."
]

@onready var label = $Label
@onready var btn_skip = $BtnSkip # Pastikan tombol skip kamu namanya BtnSkip di Scene Tree

func _ready():
	Bgm.play()
	# Langsung jalankan cerita saat scene ini terbuka
	play_story()

func play_story():
	for text in story:
		label.text = text
		label.visible_ratio = 0.0 
		
		# Hitung kecepatan ngetik berdasarkan panjang teks
		var durasi_ngetik = text.length() * 0.05
		
		var tween = get_tree().create_tween()
		tween.tween_property(label, "visible_ratio", 1.0, durasi_ngetik)
		
		await tween.finished
		
		# Jeda 3 detik agar pemain punya waktu membaca sebelum teksnya ganti
		await get_tree().create_timer(3.0).timeout

	# Kalau cerita habis, otomatis pindah ke Map 2
	get_tree().change_scene_to_file("res://map_2.tscn")

func _on_btn_skip_pressed():
	# Kalau pemain tekan skip, langsung lempar ke Map 2
	get_tree().change_scene_to_file("res://map_2.tscn")
