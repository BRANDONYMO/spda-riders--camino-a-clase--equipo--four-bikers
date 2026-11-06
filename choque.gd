extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Creamos una etiqueta temporal por código para mostrar cuántos intentos quedan
	if get_tree().has_meta("vidas_guardadas"):
		var vidas_restantes = get_tree().get_meta("vidas_guardadas")
		var label_intentos = Label.new()
		label_intentos.text = "Te quedan " + str(vidas_restantes) + " vidas (intentos)."
		label_intentos.add_theme_font_size_override("font_size", 26)
		# Lo centramos en la pantalla
		label_intentos.position = Vector2(380, 260)
		add_child(label_intentos)

func _on_reintentar_pressed():
	get_tree().change_scene_to_file("res://nivel_1.tscn")

func _on_regresaralmenu_pressed():
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().quit()