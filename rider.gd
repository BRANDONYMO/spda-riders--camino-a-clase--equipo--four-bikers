extends CharacterBody2D

var carriles = [480, 550]
var carril_actual = 1 
var ancho_deseado = 110.0

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var fondo1 = $"../Fondo1"
@onready var fondo2 = $"../Fondo2"

var tiempo_spawn = 0.0
var elementos_activos = []

var monedas = 0
var gasolina = 100.0
var vidas = 3
var tiene_turbo = false
var tiempo_turbo = 0.0

# -------------------------------------------------
# --- VARIABLES DE META Y DISTANCIA (AJUSTADAS) ---
# -------------------------------------------------
# Distancia actual que ha recorrido la moto
var distancia_recorrida = 0.0
# Distancia total para ganar el nivel
var distancia_meta = 45000.0 
# Bandera para la señal de aviso UTVM al 90% del recorrido
var senal_utvm_creada = false
# Bandera para saber si ya salió la recta final con la fachada UTVM y la meta
var recta_final_creada = false
# Control para detener el fondo al encuadrar la UTVM y estacionar la moto
var nodo_utvm_ref = null
var ancho_utvm_escalado = 0.0
var fondo_detenido = false
var estacionando_en_utvm = false
var nivel_terminado = false
# -------------------------------------------------

var label_monedas_texto = Label.new()
var barra_gasolina = ProgressBar.new()
var label_vidas_texto = Label.new()
var label_turbo_estado = Label.new()
# --- VARIABLES DE PROGRESO A LA META ---
var barra_progreso_meta = ProgressBar.new()
var label_progreso_meta = Label.new()

var rutas_obstaculos = [
	"res://images/03_Objetos_Interactivos/roca_obstaculo.png",
	"res://images/03_Objetos_Interactivos/cono_trafico.png",
	"res://images/03_Objetos_Interactivos/llantas_apiladas.png",
	"res://images/03_Objetos_Interactivos/caja_madera.png",
	"res://images/03_Objetos_Interactivos/barrera_construccion.png"
]

var rutas_coleccionables = [
	"res://images/03_Objetos_Interactivos/moneda_coleccionable.png",
	"res://images/03_Objetos_Interactivos/galon_gasolina.png",
	"res://images/03_Objetos_Interactivos/turbo_icono.png"
]

func _ready():
	# Guardamos en memoria que estamos en el Nivel 1 por si choca o pierde
	get_tree().set_meta("nivel_actual", "res://nivel_1.tscn")
	
	# Recupera las vidas y monedas de la memoria si vienes de la pantalla de choque
	if get_tree().has_meta("vidas_guardadas"):
		vidas = get_tree().get_meta("vidas_guardadas")
	if get_tree().has_meta("monedas_guardadas"):
		monedas = get_tree().get_meta("monedas_guardadas")
		
	# TRUCO 3D: Forzamos a que la moto se dibuje por encima de la meta y los obstáculos
	z_index = 10
		
	position.x = 200
	position.y = carriles[carril_actual]
	anim_player.play("Idle")
	ajustar_tamano()
	crear_hud_completo()

func crear_hud_completo():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	var icon_moneda = TextureRect.new()
	icon_moneda.texture = load("res://images/03_Objetos_Interactivos/moneda_coleccionable.png")
	icon_moneda.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon_moneda.size = Vector2(25, 25)
	icon_moneda.position = Vector2(20, 15)
	canvas_layer.add_child(icon_moneda)
	
	label_monedas_texto.text = ": " + str(monedas)
	label_monedas_texto.position = Vector2(50, 18)
	label_monedas_texto.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(label_monedas_texto)
	
	var icon_gas = TextureRect.new()
	icon_gas.texture = load("res://images/03_Objetos_Interactivos/galon_gasolina.png")
	icon_gas.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon_gas.size = Vector2(25, 25)
	icon_gas.position = Vector2(150, 15)
	canvas_layer.add_child(icon_gas)
	
	barra_gasolina.min_value = 0
	barra_gasolina.max_value = 100
	barra_gasolina.value = 100
	barra_gasolina.size = Vector2(120, 18)
	barra_gasolina.position = Vector2(180, 18)
	canvas_layer.add_child(barra_gasolina)
	
	var icon_vida = TextureRect.new()
	icon_vida.texture = load("res://images/06_Senales_UI/vidas_corazones_1.png")
	icon_vida.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon_vida.size = Vector2(40, 20)
	icon_vida.position = Vector2(330, 17)
	canvas_layer.add_child(icon_vida)
	
	label_vidas_texto.text = ": " + str(vidas)
	label_vidas_texto.position = Vector2(375, 18)
	label_vidas_texto.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(label_vidas_texto)
	
	var icon_turbo = TextureRect.new()
	icon_turbo.texture = load("res://images/03_Objetos_Interactivos/turbo_icono.png")
	icon_turbo.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon_turbo.size = Vector2(25, 25)
	icon_turbo.position = Vector2(450, 15)
	canvas_layer.add_child(icon_turbo)
	
	label_turbo_estado.text = ": SIN TURBO"
	label_turbo_estado.position = Vector2(480, 18)
	label_turbo_estado.add_theme_font_size_override("font_size", 16)
	canvas_layer.add_child(label_turbo_estado)
	
	# --- PROGRESO DEL NIVEL (ESQUINA SUPERIOR DERECHA) ---
	var panel_meta = ColorRect.new()
	panel_meta.color = Color(0, 0, 0, 0.65)
	panel_meta.size = Vector2(250, 52)
	panel_meta.position = Vector2(882, 8)
	canvas_layer.add_child(panel_meta)
	
	label_progreso_meta.text = "META (UTVM): 0%"
	label_progreso_meta.position = Vector2(895, 12)
	label_progreso_meta.add_theme_font_size_override("font_size", 14)
	canvas_layer.add_child(label_progreso_meta)
	
	barra_progreso_meta.min_value = 0
	barra_progreso_meta.max_value = 100
	barra_progreso_meta.value = 0
	barra_progreso_meta.show_percentage = false
	barra_progreso_meta.size = Vector2(225, 16)
	barra_progreso_meta.position = Vector2(895, 36)
	
	var estilo_fondo_meta = StyleBoxFlat.new()
	estilo_fondo_meta.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	estilo_fondo_meta.set_corner_radius_all(4)
	
	var estilo_lleno_meta = StyleBoxFlat.new()
	estilo_lleno_meta.bg_color = Color(0.18, 0.85, 0.35, 1.0)
	estilo_lleno_meta.set_corner_radius_all(4)
	
	barra_progreso_meta.add_theme_stylebox_override("background", estilo_fondo_meta)
	barra_progreso_meta.add_theme_stylebox_override("fill", estilo_lleno_meta)
	canvas_layer.add_child(barra_progreso_meta)
	
	var icon_bandera = TextureRect.new()
	icon_bandera.texture = load("res://images/06_Senales_UI/meta_1.png")
	icon_bandera.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon_bandera.size = Vector2(22, 22)
	icon_bandera.position = Vector2(1098, 10)
	canvas_layer.add_child(icon_bandera)

func _process(delta):
	# Si ya terminó y quedó estacionado frente a la puerta UTVM
	if nivel_terminado:
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")
		return
		
	# Si ya cruzó la bandera de meta, avanza suave hasta pararse justo frente a la puerta UTVM
	if estacionando_en_utvm:
		var destino_puerta_x = 850.0
		if position.x < destino_puerta_x:
			position.x = min(position.x + 380.0 * delta, destino_puerta_x)
			if anim_player.current_animation != "Run":
				anim_player.play("Run")
		else:
			nivel_terminado = true
			anim_player.play("Idle")
			finalizar_nivel_utvm()
		ajustar_tamano()
		return
		
	var velocidad_base = 650
	
	# Lógica para activar el turbo con la tecla X o Enter
	if tiene_turbo and (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_X)):
		tiempo_turbo = 3.0
		tiene_turbo = false
		label_turbo_estado.text = ": ¡TURBO ACTIVO!"
		
	# Si el turbo está activo, aumentamos la velocidad y restamos el tiempo
	if tiempo_turbo > 0:
		tiempo_turbo -= delta
		velocidad_base = 1100
		if tiempo_turbo <= 0:
			label_turbo_estado.text = ": SIN TURBO"

	var velocidad = 0
	
	# Movimiento hacia adelante (derecha)
	if Input.is_action_pressed("ui_right"):
		velocidad = velocidad_base
		if anim_player.current_animation != "Run":
			anim_player.play("Run")
			
		gasolina -= delta * 1.0
		if gasolina <= 0:
			# Si se acaba la gasolina, manda directo a Game Over guardando el Nivel 1
			get_tree().set_meta("vidas_guardadas", 3)
			get_tree().set_meta("monedas_guardadas", 0)
			get_tree().set_meta("nivel_actual", "res://nivel_1.tscn")
			get_tree().change_scene_to_file("res://game_over.tscn")
		barra_gasolina.value = gasolina
		
	# Movimiento hacia atrás (izquierda) - Frena
	elif Input.is_action_pressed("ui_left"):
		velocidad = 250
		if anim_player.current_animation != "Run":
			anim_player.play("Run")
	# Si no presiona nada, se queda en Idle (Frenado completo)
	else:
		velocidad = 0
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")

	ajustar_tamano()

	# Movimiento del fondo (Parallax básico) mientras la UTVM no haya llenado la pantalla
	if velocidad > 0 and fondo1 and fondo2:
		if not fondo_detenido:
			fondo1.position.x -= velocidad * delta
			fondo2.position.x -= velocidad * delta
			
			if fondo1.position.x <= -1152:
				fondo1.position.x = fondo2.position.x + 1152
			if fondo2.position.x <= -1152:
				fondo2.position.x = fondo1.position.x + 1152

			# ---------------------------------------------------------------
			# --- LÓGICA DE DISTANCIA PARA SEÑAL, FACHADA UTVM Y META ---
			# ---------------------------------------------------------------
			distancia_recorrida += velocidad * delta
			
			# Actualiza la barra de progreso en la esquina superior derecha
			var porcentaje_meta = clampf((distancia_recorrida / distancia_meta) * 100.0, 0.0, 100.0)
			barra_progreso_meta.value = porcentaje_meta
			label_progreso_meta.text = "META (UTVM): " + str(int(porcentaje_meta)) + "%"
			
			# Al llegar al 90% del recorrido aparece el letrero de la UTVM
			if distancia_recorrida >= (distancia_meta * 0.90) and not senal_utvm_creada:
				crear_senal_utvm()
				senal_utvm_creada = true
			
			# Entra la única fachada de la UTVM junto con la meta
			if distancia_recorrida >= (distancia_meta - 1152.0) and not recta_final_creada:
				generar_recta_final_utvm()
				recta_final_creada = true
			# ---------------------------------------------------------------

			# Mueve los obstáculos, monedas, señal, fachada UTVM y meta hacia la moto
			for elem in elementos_activos:
				if is_instance_valid(elem):
					elem.position.x -= velocidad * delta
					# No borramos la fachada de la UTVM para que cubra todo el fondo al llegar
					if not elem.has_meta("es_fachada_utvm") and elem.position.x < -150:
						elem.queue_free()
						elementos_activos.erase(elem)
						
			# Si el borde derecho de utvm1.png ya llegó al borde derecho de la pantalla, frenamos el fondo
			if is_instance_valid(nodo_utvm_ref):
				var limite_x = 1152.0 - ancho_utvm_escalado
				if nodo_utvm_ref.position.x <= limite_x:
					var exceso = limite_x - nodo_utvm_ref.position.x
					for elem in elementos_activos:
						if is_instance_valid(elem):
							elem.position.x += exceso
					fondo_detenido = true
		else:
			# Con la fachada UTVM ya encuadrada sin cortes, la moto avanza hacia la meta y la puerta
			position.x += velocidad * delta

	# --- TIEMPO DE SPAWN AJUSTADO ---
	# Dejan de salir obstáculos normales cuando empieza a entrar la fachada de la UTVM
	if velocidad > 0 and not recta_final_creada:
		tiempo_spawn += delta
		if tiempo_spawn >= 1.15:
			tiempo_spawn = 0.0
			crear_elemento_aleatorio()

	# Cambiar al carril de arriba
	if Input.is_action_just_pressed("ui_up"):
		carril_actual = 0
		position.y = carriles[carril_actual]
		anim_player.play("Jump")
		ajustar_tamano()
		
	# Cambiar al carril de abajo
	elif Input.is_action_just_pressed("ui_down"):
		carril_actual = 1
		position.y = carriles[carril_actual]
		anim_player.play("Fall")
		ajustar_tamano()

# ---------------------------------------------------
# --- FUNCIÓN PARA EL LETRERO UTVM AL 90% ---
# ---------------------------------------------------
func crear_senal_utvm():
	var sprite_senal = Sprite2D.new()
	sprite_senal.texture = load("res://images/06_Senales_UI/utvm_1.png")
	sprite_senal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_senal.scale = Vector2(0.24, 0.24)
	sprite_senal.z_index = 3
	# Sale por la derecha en la orilla superior de la pista (banqueta) para no estorbar
	sprite_senal.position = Vector2(1220.0, 432.0)
	
	get_parent().add_child(sprite_senal)
	elementos_activos.append(sprite_senal)
# ---------------------------------------------------

# ---------------------------------------------------
# --- FUNCIÓN QUE CREA LA FACHADA UTVM Y LA META ---
# ---------------------------------------------------
func generar_recta_final_utvm():
	# 1. Única imagen de la fachada de la UTVM (utvm1.png) alineada al borde del fondo actual
	var tex_utvm = load("res://images/07_Fondos/nivel1utvm.png")
	# Altura ligeramente mayor y desplazada -25 px en Y para que la pista y el barandal empaten
	var escala_y = 646.0 / float(tex_utvm.get_height())
	ancho_utvm_escalado = float(tex_utvm.get_width()) * escala_y
	
	# Empata exactamente con el borde derecho del fondo que viene entrando para evitar cortes
	var x_inicio_utvm = max(fondo1.position.x, fondo2.position.x) + 1152.0
	
	var nodo_utvm = Node2D.new()
	nodo_utvm.z_index = 1
	nodo_utvm.position = Vector2(x_inicio_utvm, 0.0)
	nodo_utvm.set_meta("es_fachada_utvm", true)
	
	var sprite_utvm = Sprite2D.new()
	sprite_utvm.texture = tex_utvm
	sprite_utvm.centered = false
	sprite_utvm.scale = Vector2(escala_y, escala_y)
	nodo_utvm.add_child(sprite_utvm)
	
	get_parent().add_child(nodo_utvm)
	elementos_activos.append(nodo_utvm)
	nodo_utvm_ref = nodo_utvm
	
	# 2. Arco de Meta grande (cubre ambos carriles) colocado unos cm antes de la puerta UTVM
	var area = Area2D.new()
	area.z_index = 5
	var sprite_elem = Sprite2D.new()
	sprite_elem.texture = load("res://images/06_Senales_UI/meta_1.png")
	sprite_elem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_elem.scale = Vector2(0.75, 0.75)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 320)
	
	# Colocada antes de la fachada UTVM para cruzarla y luego pararse frente a la puerta
	var pos_x_meta = x_inicio_utvm + (ancho_utvm_escalado * 0.56)
	area.position = Vector2(pos_x_meta, 505.0)
	
	area.add_child(sprite_elem)
	col.shape = shape
	area.add_child(col)
	
	# Conecta la colisión para saber cuándo la moto toca la meta
	area.body_entered.connect(func(body):
		if body == self:
			if not estacionando_en_utvm and not nivel_terminado:
				estacionando_en_utvm = true
				barra_progreso_meta.value = 100.0
				label_progreso_meta.text = "META (UTVM): 100%"
				print("¡NIVEL COMPLETADO!")
	)
	
	get_parent().add_child(area)
	elementos_activos.append(area)

func finalizar_nivel_utvm():
	# Se queda parado frente a la puerta de la UTVM 2.2 segundos antes de ir al menú
	await get_tree().create_timer(2.2).timeout
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://nivel_completado.tscn")
# ---------------------------------------------------

# ---------------------------------------------------
# --- FUNCIÓN PARA CREAR OBSTÁCULOS Y MONEDAS ---
# ---------------------------------------------------
func crear_elemento_aleatorio():
	var area = Area2D.new()
	area.z_index = 4
	# Decide aleatoriamente (50/50) si es moneda/gasolina o si es un obstáculo
	var es_coleccionable = randi() % 2 == 0
	
	var ruta_txt = ""
	if es_coleccionable:
		ruta_txt = rutas_coleccionables[randi() % rutas_coleccionables.size()]
	else:
		ruta_txt = rutas_obstaculos[randi() % rutas_obstaculos.size()]
		
	var sprite_elem = Sprite2D.new()
	sprite_elem.texture = load(ruta_txt)
	sprite_elem.scale = Vector2(0.06, 0.06)
	area.add_child(sprite_elem)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 22.0
	col.shape = shape
	area.add_child(col)
	
	# Elige un carril al azar para aparecer
	var y_elegido = carriles[randi() % carriles.size()]
	area.position = Vector2(1200, y_elegido)
	
	# Conecta la colisión del objeto con la moto
	area.body_entered.connect(func(body):
		if body == self:
			if es_coleccionable:
				if "moneda" in ruta_txt:
					monedas += 1
					get_tree().set_meta("monedas_guardadas", monedas)
					label_monedas_texto.text = ": " + str(monedas)
				elif "gasolina" in ruta_txt:
					# Suma gasolina pero sin pasarse de 100
					gasolina = min(100.0, gasolina + 35.0)
					barra_gasolina.value = gasolina
				elif "turbo" in ruta_txt:
					tiene_turbo = true
					label_turbo_estado.text = ": ¡LISTO (Presiona X)!"
				
				# Elimina el coleccionable al agarrarlo
				area.queue_free()
				elementos_activos.erase(area)
			else:
				# Si es obstáculo, resta 1 vida, guarda que estabas en Nivel 1 y cambia a la escena
				vidas -= 1
				get_tree().set_meta("vidas_guardadas", vidas)
				get_tree().set_meta("nivel_actual", "res://nivel_1.tscn")
				
				if vidas > 0:
					# Aún hay vidas, va a la escena de choque
					get_tree().change_scene_to_file("res://choque.tscn")
				else:
					# Se acabaron las vidas, va a Game Over
					get_tree().set_meta("vidas_guardadas", 3)
					get_tree().set_meta("monedas_guardadas", 0)
					get_tree().change_scene_to_file("res://game_over.tscn")
	)
	
	get_parent().add_child(area)
	elementos_activos.append(area)
# ---------------------------------------------------

func ajustar_tamano():
	# Calcula el tamaño correcto de la moto según sus frames de animación
	if sprite and sprite.texture:
		var ancho_frame = float(sprite.texture.get_width()) / float(sprite.hframes)
		if ancho_frame > 0:
			var escala = ancho_deseado / ancho_frame
			sprite.scale = Vector2(escala, escala)
