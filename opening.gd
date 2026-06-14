extends Control

var story = [
	"Dahulu kala, Putri Penyihir Morgana dikurung di penjara bawah tanah sebuah istana kuno oleh kutukan sihir yang kuat.",
	"Mendengar kisah tersebut, Raja Barbar Alaric bertekad untuk menyelamatkannya.",
	"Untuk membuka gerbang menuju penjara Morgana, Alaric harus menemukan artefak asli yang tersembunyi di dalam istana.",
	"Setelah berhasil menemukannya, gerbang bawah tanah pun terbuka."
]

@onready var label = $Label
@onready var btn_skip = $BtnSkip 
@onready var btn_start = $BtnStart 

func _ready():
	label.hide()
	btn_skip.hide()
	
	btn_start.show()

func play_story():
	for text in story:
		label.text = text
		label.visible_ratio = 0.0 
		
		var durasi_ngetik = text.length() * 0.05
		
		var tween = get_tree().create_tween()
		tween.tween_property(label, "visible_ratio", 1.0, durasi_ngetik)
		
		await tween.finished
		await get_tree().create_timer(2.0).timeout

	get_tree().change_scene_to_file("res://Main.tscn")

func _on_btn_start_pressed():
	btn_start.hide() 
	label.show() 
	btn_skip.show() 
	Bgm.play()
	play_story()

func _on_btn_skip_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")
