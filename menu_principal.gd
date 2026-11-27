extends Control

func _ready():
	# Asegurarnos de que el mouse sea visible para poder darle clic a los botones
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Música de fondo del lobby en bucle
	var audio_lobby = AudioStreamPlayer.new()
	audio_lobby.stream = load("res://audio/fondolobby.mp3")
	audio_lobby.volume_db = -6.0
	audio_lobby.finished.connect(func(): audio_lobby.play())
	add_child(audio_lobby)
	audio_lobby.play()
	
	# Revisamos hasta qué nivel lleva desbloqueado (por defecto solo el 1)
	var desbloqueado = get_tree().get_meta("nivel_desbloqueado", 1)
	
	# Busca todos los botones del menú sin importar mayúsculas o minúsculas
	for btn in find_children("*", "Button", true, false):
		if "2" in btn.text or "2" in btn.name:
			if desbloqueado < 2:
				btn.disabled = true
				btn.text = "🔒 Nivel 2"
			else:
				btn.disabled = false
				btn.text = "🔓 Nivel 2"
		elif "3" in btn.text or "3" in btn.name:
			if desbloqueado < 3:
				btn.disabled = true
				btn.text = "🔒 Nivel 3"
			else:
				btn.disabled = false
				btn.text = "🔓 Nivel 3"

func _on_btn_nivel_1_pressed():
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://nivel_1.tscn")

func _on_btn_nivel_2_pressed():
	if get_tree().get_meta("nivel_desbloqueado", 1) < 2:
		return
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://nivel_2.tscn")

func _on_btn_nivel_3_pressed():
	if get_tree().get_meta("nivel_desbloqueado", 1) < 3:
		return
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://nivel_3.tscn")

func _on_btn_salir_pressed():
	get_tree().quit()
