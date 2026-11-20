extends Control

var fondo = TextureRect.new()
var panel_barra = ColorRect.new()
var label_estado = Label.new()
var barra = ProgressBar.new()
var progreso = 0.0

# Cambia esta ruta según a dónde quieras que salte al terminar (por ejemplo, tu menú principal)
var siguiente_escena = "res://menu_principal.tscn"

func _ready():
	# 1. Configuramos el fondo a pantalla completa (1152x648) con nuestra imagen chida
	fondo.texture = load("res://images/07_Fondos/fondo_carga.png")
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.size = Vector2(1152, 648)
	add_child(fondo)
	
	# 2. Panel oscuro semitransparente en la parte inferior para que la barra resalte chido
	panel_barra.color = Color(0, 0, 0, 0.75)
	panel_barra.size = Vector2(640, 75)
	panel_barra.position = Vector2(256, 545)
	add_child(panel_barra)
	
	# 3. Texto dinámico del porcentaje de carga
	label_estado.text = "CARGANDO CAMINO A CLASE... 0%"
	label_estado.position = Vector2(370, 552)
	label_estado.add_theme_font_size_override("font_size", 20)
	add_child(label_estado)
	
	# 4. Configuración pura por código de la Barra de Progreso
	barra.min_value = 0
	barra.max_value = 100
	barra.value = 0
	barra.show_percentage = false
	barra.size = Vector2(600, 26)
	barra.position = Vector2(276, 584)
	
	# Estilos visuales de la barra (fondo oscuro y barra naranja tipo turbo)
	var estilo_fondo = StyleBoxFlat.new()
	estilo_fondo.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	estilo_fondo.set_corner_radius_all(6)
	
	var estilo_lleno = StyleBoxFlat.new()
	estilo_lleno.bg_color = Color(1.0, 0.55, 0.0, 1.0)
	estilo_lleno.set_corner_radius_all(6)
	
	barra.add_theme_stylebox_override("background", estilo_fondo)
	barra.add_theme_stylebox_override("fill", estilo_lleno)
	add_child(barra)

func _process(delta):
	if progreso < 100.0:
		# La barra va subiendo de forma fluida y real
		progreso += delta * 30.0
		barra.value = min(progreso, 100.0)
		label_estado.text = "CARGANDO CAMINO A CLASE... " + str(int(barra.value)) + "%"
	else:
		# Al llegar al 100%, cambia de escena automáticamente por código
		get_tree().change_scene_to_file(siguiente_escena)