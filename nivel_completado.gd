extends Control

func _ready():
	# Sonido de victoria
	var sfx_victoria = AudioStreamPlayer.new()
	sfx_victoria.stream = load("res://audio/victoria.mp3")
	add_child(sfx_victoria)
	sfx_victoria.play()

	# Fondo oscuro
	var fondo = ColorRect.new()
	fondo.color = Color(0.08, 0.1, 0.15, 1.0)
	fondo.size = Vector2(1152, 648)
	add_child(fondo)
	
	# Trofeo
	var trofeo = TextureRect.new()
	trofeo.texture = load("res://images/06_Senales_UI/trofeo_1.png")
	trofeo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	trofeo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trofeo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trofeo.size = Vector2(220, 220)
	trofeo.position = Vector2(466, 130)
	add_child(trofeo)
	
	# Detecta qué nivel acabas de terminar y desbloquea el siguiente
	var nivel_actual = get_tree().get_meta("nivel_actual", "res://nivel_1.tscn")
	var desbloqueado = get_tree().get_meta("nivel_desbloqueado", 1)
	var siguiente_escena = "res://menu_principal.tscn"
	var texto_subtitulo = "¡Juego completado! Regresando al menú principal..."
	
	if nivel_actual == "res://nivel_1.tscn":
		siguiente_escena = "res://nivel_2.tscn"
		texto_subtitulo = "Pasando al Nivel 2..."
		if desbloqueado < 2:
			get_tree().set_meta("nivel_desbloqueado", 2)
	elif nivel_actual == "res://nivel_2.tscn":
		siguiente_escena = "res://nivel_3.tscn"
		texto_subtitulo = "Pasando al Nivel 3..."
		if desbloqueado < 3:
			get_tree().set_meta("nivel_desbloqueado", 3)
	
	# Título
	var titulo = Label.new()
	titulo.text = "¡NIVEL COMPLETADO!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size = Vector2(1152, 70)
	titulo.position = Vector2(0, 370)
	titulo.add_theme_font_size_override("font_size", 50)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	add_child(titulo)
	
	# Subtítulo
	var subtitulo = Label.new()
	subtitulo.text = texto_subtitulo
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.size = Vector2(1152, 40)
	subtitulo.position = Vector2(0, 445)
	subtitulo.add_theme_font_size_override("font_size", 22)
	add_child(subtitulo)
	
	# Espera 5 segundos y pasa al siguiente nivel (o al menú si era el Nivel 3)
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file(siguiente_escena)
