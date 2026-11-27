extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Sonido de Game Over
	var sfx_gameover = AudioStreamPlayer.new()
	sfx_gameover.stream = load("res://audio/gameover.mp3")
	add_child(sfx_gameover)
	sfx_gameover.play()

func _on_reintentar_pressed():
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	var nivel_a_cargar = get_tree().get_meta("nivel_actual", "res://nivel_1.tscn")
	get_tree().change_scene_to_file(nivel_a_cargar)

func _on_regresaralmenu_pressed():
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://menu_principal.tscn")
