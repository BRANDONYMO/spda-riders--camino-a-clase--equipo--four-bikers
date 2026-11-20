extends CharacterBody2D

var carriles = [510, 580]
var carril_actual = 1 
var ancho_deseado = 115.0

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var fondo1 = $"../Fondo1"
@onready var fondo2 = $"../Fondo2"

var tiempo_spawn = 0.0
var elementos_activos = []

# Variables para animar la moto nueva de forma fluida
var frame_moto = 0
var timer_moto = 0.0
var esta_corriendo = false
var rects_moto = []

var monedas = 0
var gasolina = 100.0
var vidas = 3
var tiene_turbo = false
var tiempo_turbo = 0.0

# -------------------------------------------------
# --- VARIABLES DE META Y DISTANCIA ---
# -------------------------------------------------
var distancia_recorrida = 0.0
var distancia_meta = 60000.0 
var senal_utvm_creada = false
var recta_final_creada = false
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

# --- LISTA DE OBSTÁCULOS CON PRIORIDAD A LOS NUEVOS ---
var rutas_obstaculos = [
	"res://images/sprites run/automovil run.png",
	"res://images/sprites run/automovil run.png",
	"res://images/sprites run/muchacho en el telefonno run.png",
	"res://images/sprites run/muchacho en el telefonno run.png",
	"res://images/sprites run/muchacho run.png",
	"res://images/sprites run/muchacho run.png",
	"res://images/sprites run/ebrio run.png",
	"res://images/sprites run/muchacha en el fon run.png",
	"res://images/sprites run/muchacha run.png",
	"res://images/sprites run/viejito run run.png",
	"res://images/sprites run/viejito run.png",
	"res://images/sprites run/ciclista run.png",
	"res://images/sprites run/trabajador obra run.png",
	"res://images/sprites run/vaca run.png",
	"res://images/sprites run/vendedor run.png",
	"res://images/02_Obstaculos_NPCs/maguey1.png",
	"res://images/06_Senales_UI/tronco_1.png",
	"res://images/03_Objetos_Interactivos/roca_obstaculo.png",
	"res://images/03_Objetos_Interactivos/cono_trafico.png",
	"res://images/06_Senales_UI/charco_aceite_1.png",
	"res://images/06_Senales_UI/senal_peligro_1.png",
	"res://images/06_Senales_UI/stop_1.png"
]

var rutas_coleccionables = [
	"res://images/03_Objetos_Interactivos/moneda_coleccionable.png",
	"res://images/03_Objetos_Interactivos/galon_gasolina.png",
	"res://images/03_Objetos_Interactivos/turbo_icono.png"
]

func _ready():
	# Guardamos en memoria que estamos en el Nivel 3 por si choca o pierde
	get_tree().set_meta("nivel_actual", "res://nivel_3.tscn")
	
	if get_tree().has_meta("vidas_guardadas"):
		vidas = get_tree().get_meta("vidas_guardadas")
	if get_tree().has_meta("monedas_guardadas"):
		monedas = get_tree().get_meta("monedas_guardadas")
		
	z_index = 10
	position.x = 200
	position.y = carriles[carril_actual]
	
	if anim_player:
		anim_player.stop()
		anim_player.active = false
		
	sprite.texture = load("res://images/sprites run/motociclista npc run.png")
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.region_enabled = true
	
	preparar_frames_moto()
	actualizar_recorte_moto()
	crear_hud_completo()

func preparar_frames_moto():
	if not sprite or not sprite.texture:
		return
	var img = sprite.texture.get_image()
	var tex_w = img.get_width()
	var tex_h = img.get_height()
	
	# Escaneamos las 8 motos buscando dónde hay dibujo real para que todas midan igual y no tiemblen
	var inicios = []
	var finales = []
	var dentro = false
	
	for x in range(tex_w):
		var tiene_pixel = false
		for y in range(0, tex_h, 2):
			if img.get_pixel(x, y).a > 0.1:
				tiene_pixel = true
				break
		if tiene_pixel and not dentro:
			dentro = true
			inicios.append(x)
		elif not tiene_pixel and dentro:
			dentro = false
			finales.append(x)
	if dentro:
		finales.append(tex_w)
		
	rects_moto.clear()
	if inicios.size() == 8:
		# Calculamos un ancho fijo promedio para que la moto nunca cambie de tamaño al correr
		var ancho_fijo = 0.0
		for i in range(8):
			ancho_fijo += float(finales[i] - inicios[i])
		ancho_fijo /= 8.0
		
		for i in range(8):
			var centro = float(inicios[i] + finales[i]) / 2.0
			var rx = clampf(centro - (ancho_fijo / 2.0), 0.0, float(tex_w) - ancho_fijo)
			rects_moto.append(Rect2(rx, 0, ancho_fijo, tex_h))
	else:
		# Respaldo en 8 partes iguales si la textura está pegada
		var celda = float(tex_w) / 8.0
		for i in range(8):
			rects_moto.append(Rect2(i * celda + 2.0, 0, celda - 4.0, tex_h))

func actualizar_recorte_moto():
	if not sprite or not sprite.texture or rects_moto.is_empty():
		return
	var rect_actual = rects_moto[frame_moto % rects_moto.size()]
	sprite.region_rect = rect_actual
	
	if rect_actual.size.x > 0:
		var escala = ancho_deseado / rect_actual.size.x
		sprite.scale = Vector2(escala, escala)

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
		frame_moto = 0
		actualizar_recorte_moto()
		return
		
	# Si ya cruzó la bandera de meta, avanza suave hasta pararse justo frente a la puerta UTVM
	if estacionando_en_utvm:
		var destino_puerta_x = 850.0
		if position.x < destino_puerta_x:
			position.x = min(position.x + 380.0 * delta, destino_puerta_x)
			timer_moto += delta
			if timer_moto >= 0.07:
				timer_moto = 0.0
				frame_moto = (frame_moto + 1) % 8
				actualizar_recorte_moto()
		else:
			nivel_terminado = true
			frame_moto = 0
			actualizar_recorte_moto()
			finalizar_nivel_utvm()
		return
		
	var velocidad_base = 820
	
	if tiene_turbo and (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_X)):
		tiempo_turbo = 3.0
		tiene_turbo = false
		label_turbo_estado.text = ": ¡TURBO ACTIVO!"
		
	if tiempo_turbo > 0:
		tiempo_turbo -= delta
		velocidad_base = 1300
		if tiempo_turbo <= 0:
			label_turbo_estado.text = ": SIN TURBO"

	var velocidad = 0
	
	if Input.is_action_pressed("ui_right"):
		velocidad = velocidad_base
		esta_corriendo = true
			
		gasolina -= delta * 1.3
		if gasolina <= 0:
			get_tree().set_meta("vidas_guardadas", 3)
			get_tree().set_meta("monedas_guardadas", 0)
			get_tree().set_meta("nivel_actual", "res://nivel_3.tscn")
			get_tree().change_scene_to_file("res://game_over.tscn")
		barra_gasolina.value = gasolina
		
	elif Input.is_action_pressed("ui_left"):
		velocidad = 300
		esta_corriendo = true
	else:
		velocidad = 0
		esta_corriendo = false

	if esta_corriendo:
		timer_moto += delta
		if timer_moto >= 0.07:
			timer_moto = 0.0
			frame_moto = (frame_moto + 1) % 8
			actualizar_recorte_moto()
	else:
		frame_moto = 0
		actualizar_recorte_moto()

	if not fondo_detenido:
		if velocidad > 0 and fondo1 and fondo2:
			fondo1.position.x -= velocidad * delta
			fondo2.position.x -= velocidad * delta
			
			if fondo1.position.x <= -1152:
				fondo1.position.x = fondo2.position.x + 1152
			if fondo2.position.x <= -1152:
				fondo2.position.x = fondo1.position.x + 1152

			distancia_recorrida += velocidad * delta
			
			# Actualiza la barra de progreso en la esquina superior derecha
			var porcentaje_meta = clampf((distancia_recorrida / distancia_meta) * 100.0, 0.0, 100.0)
			barra_progreso_meta.value = porcentaje_meta
			label_progreso_meta.text = "META (UTVM): " + str(int(porcentaje_meta)) + "%"
			
			# Al llegar al 90% del recorrido aparece el letrero de la UTVM
			if distancia_recorrida >= (distancia_meta * 0.90) and not senal_utvm_creada:
				crear_senal_utvm()
				senal_utvm_creada = true
				
			# Entra la única fachada de la UTVM (utvm3.png) junto con la meta
			if distancia_recorrida >= (distancia_meta - 1152.0) and not recta_final_creada:
				generar_recta_final_utvm()
				recta_final_creada = true

		# --- EXPLICACIÓN PARA EL PROFESOR: MOVIMIENTO INDEPENDIENTE ---
		for elem in elementos_activos:
			if is_instance_valid(elem):
				var velocidad_movimiento = velocidad 
				
				if elem.has_meta("velocidad_propia"):
					velocidad_movimiento -= elem.get_meta("velocidad_propia")
					
				elem.position.x -= velocidad_movimiento * delta
				
				# No borramos la fachada de la UTVM para que cubra todo el fondo al llegar
				if not elem.has_meta("es_fachada_utvm") and elem.position.x < -150:
					elem.queue_free()
					elementos_activos.erase(elem)

		# Si el borde derecho de utvm3.png ya llegó al borde derecho de la pantalla, frenamos el fondo
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

	if velocidad > 0 and not recta_final_creada:
		tiempo_spawn += delta
		if tiempo_spawn >= 0.45: 
			tiempo_spawn = 0.0
			crear_elemento_aleatorio()

	if Input.is_action_just_pressed("ui_up"):
		carril_actual = 0
		position.y = carriles[carril_actual]
		actualizar_recorte_moto()
		
	elif Input.is_action_just_pressed("ui_down"):
		carril_actual = 1
		position.y = carriles[carril_actual]
		actualizar_recorte_moto()

# ---------------------------------------------------
# --- FUNCIÓN PARA EL LETRERO UTVM AL 90% ---
# ---------------------------------------------------
func crear_senal_utvm():
	var sprite_senal = Sprite2D.new()
	sprite_senal.texture = load("res://images/06_Senales_UI/utvm_1.png")
	sprite_senal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_senal.scale = Vector2(0.24, 0.24)
	sprite_senal.z_index = 3
	# Sentada sobre la banqueta (ajusta 455.0 si la quieres un pelín más arriba o abajo)
	sprite_senal.position = Vector2(1220.0, 455.0)
	
	get_parent().add_child(sprite_senal)
	elementos_activos.append(sprite_senal)
# ---------------------------------------------------

# ---------------------------------------------------
# --- FUNCIÓN QUE CREA LA FACHADA UTVM Y LA META ---
# ---------------------------------------------------
func generar_recta_final_utvm():
	# 1. Única imagen de la fachada de la UTVM (utvm3.png) alineada al borde del fondo actual
	var tex_utvm = load("res://images/07_Fondos/utvm3.png")
	var escala_y = 648.0 / float(tex_utvm.get_height())
	ancho_utvm_escalado = float(tex_utvm.get_width()) * escala_y
	
	# Empata exactamente con el borde derecho del fondo que viene entrando para evitar cortes
	var x_inicio_utvm = max(fondo1.position.x, fondo2.position.x) + 1152.0
	
	var nodo_utvm = Node2D.new()
	nodo_utvm.z_index = 1
	nodo_utvm.position = Vector2(x_inicio_utvm, 5.0)
	nodo_utvm.set_meta("es_fachada_utvm", true)
	
	var sprite_utvm = Sprite2D.new()
	sprite_utvm.texture = tex_utvm
	sprite_utvm.centered = false
	sprite_utvm.scale = Vector2(escala_y, escala_y)
	nodo_utvm.add_child(sprite_utvm)
	
	get_parent().add_child(nodo_utvm)
	elementos_activos.append(nodo_utvm)
	nodo_utvm_ref = nodo_utvm
	
	# 2. Arco de Meta grande (cubre ambos carriles) colocado antes de la puerta UTVM
	var area = Area2D.new()
	area.z_index = 5
	var sprite_elem = Sprite2D.new()
	sprite_elem.texture = load("res://images/06_Senales_UI/meta_1.png")
	sprite_elem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_elem.scale = Vector2(0.75, 0.75)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 320)
	
	var pos_x_meta = x_inicio_utvm + (ancho_utvm_escalado * 0.56)
	area.position = Vector2(pos_x_meta, 535.0)
	
	area.add_child(sprite_elem)
	col.shape = shape
	area.add_child(col)
	
	area.body_entered.connect(func(body):
		if body == self:
			if not estacionando_en_utvm and not nivel_terminado:
				estacionando_en_utvm = true
				barra_progreso_meta.value = 100.0
				label_progreso_meta.text = "META (UTVM): 100%"
				print("¡NIVEL 3 COMPLETADO!")
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

func crear_elemento_aleatorio():
	var area = Area2D.new()
	area.z_index = 4
	var es_coleccionable = randi() % 3 == 0
	
	var ruta_txt = ""
	if es_coleccionable:
		ruta_txt = rutas_coleccionables[randi() % rutas_coleccionables.size()]
	else:
		ruta_txt = rutas_obstaculos[randi() % rutas_obstaculos.size()]
		
	var sprite_elem = Sprite2D.new()
	sprite_elem.texture = load(ruta_txt)
	
	var es_animado = false
	var frames_totales = 8 
	var velocidad_npc = 0 
	var es_letrero_banqueta = false
	var ancho_objetivo_npc = 0.0 # Calcula el tamaño real en pantalla sin importar la imagen
	var radio_colision = 24.0
	
	# --- TAMAÑO AUTOMÁTICO EN PÍXELES REALES PARA QUE NADA SE VEA MINI ---
	if "automovil run" in ruta_txt:
		es_animado = true
		frames_totales = 6
		ancho_objetivo_npc = 165.0 # Un carro grande y realista (más largo que tu moto)
		sprite_elem.position.y = 5
		velocidad_npc = 320
		radio_colision = 40.0
	elif "ciclista run" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 92.0 
		sprite_elem.position.y = 6 
		velocidad_npc = 220 
	elif "vaca run" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 95.0
		sprite_elem.position.y = 6
		velocidad_npc = 80 
	elif "muchacho en el telefonno run" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 68.0 # Tamaño de persona real
		sprite_elem.position.y = 4
		velocidad_npc = 130
	elif "muchacho run" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 68.0
		sprite_elem.position.y = 4
		velocidad_npc = 160
	elif "trabajador obra run" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 68.0
		sprite_elem.position.y = 4
		velocidad_npc = 150 
	elif "vendedor run" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 68.0
		sprite_elem.position.y = 4
		velocidad_npc = 120 
	elif "ebrio run" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 68.0
		sprite_elem.position.y = 4
		velocidad_npc = 90
	elif "muchacha" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 68.0
		sprite_elem.position.y = 4
		velocidad_npc = 140
	elif "viejito" in ruta_txt:
		es_animado = true
		frames_totales = 8
		ancho_objetivo_npc = 66.0 # Ya no se ve mini el abuelito
		sprite_elem.position.y = 6
		velocidad_npc = 70
	# --- OBSTÁCULOS ESTÁTICOS Y SEÑALES ---
	elif "maguey" in ruta_txt:
		sprite_elem.scale = Vector2(0.06, 0.06) 
		sprite_elem.position.y = 15 
	elif "tronco" in ruta_txt:
		sprite_elem.scale = Vector2(0.14, 0.14) 
		sprite_elem.position.y = 15 
	elif "charco_aceite" in ruta_txt:
		sprite_elem.scale = Vector2(0.12, 0.12)
		sprite_elem.position.y = 20
	elif "senal_peligro" in ruta_txt or "stop_1" in ruta_txt:
		sprite_elem.scale = Vector2(0.11, 0.11)
		sprite_elem.position.y = 0
		es_letrero_banqueta = true
	else:
		sprite_elem.scale = Vector2(0.06, 0.06)
		sprite_elem.position.y = 15 
	
	if velocidad_npc > 0:
		area.set_meta("velocidad_propia", velocidad_npc)

	if es_animado and sprite_elem.texture:
		sprite_elem.hframes = frames_totales
		sprite_elem.frame = 0
		
		# Calculamos la escala exacta según los píxeles de cada imagen para que nunca salgan mini
		var ancho_un_frame = float(sprite_elem.texture.get_width()) / float(frames_totales)
		if ancho_un_frame > 0 and ancho_objetivo_npc > 0:
			var esc_npc = ancho_objetivo_npc / ancho_un_frame
			sprite_elem.scale = Vector2(esc_npc, esc_npc)
		
		var timer = Timer.new()
		timer.wait_time = 0.08
		timer.autostart = true
		timer.timeout.connect(func():
			if is_instance_valid(sprite_elem):
				sprite_elem.frame = (sprite_elem.frame + 1) % frames_totales
		)
		area.add_child(timer)
		
	area.add_child(sprite_elem)
	
	var y_elegido = carriles[randi() % carriles.size()]
	
	if es_letrero_banqueta:
		y_elegido = 478
	else:
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = radio_colision
		col.shape = shape
		area.add_child(col)
		
		area.body_entered.connect(func(body):
			if body == self:
				if es_coleccionable:
					if "moneda" in ruta_txt:
						monedas += 1
						get_tree().set_meta("monedas_guardadas", monedas)
						label_monedas_texto.text = ": " + str(monedas)
					elif "gasolina" in ruta_txt:
						gasolina = min(100.0, gasolina + 35.0)
						barra_gasolina.value = gasolina
					elif "turbo" in ruta_txt:
						tiene_turbo = true
						label_turbo_estado.text = ": ¡LISTO (Presiona X)!"
					
					area.queue_free()
					elementos_activos.erase(area)
				else:
					vidas -= 1
					get_tree().set_meta("vidas_guardadas", vidas)
					get_tree().set_meta("nivel_actual", "res://nivel_3.tscn")
					
					if vidas > 0:
						get_tree().change_scene_to_file("res://choque.tscn")
					else:
						get_tree().set_meta("vidas_guardadas", 3)
						get_tree().set_meta("monedas_guardadas", 0)
						get_tree().change_scene_to_file("res://game_over.tscn")
		)
	
	area.position = Vector2(1200, y_elegido)
	get_parent().add_child(area)
	elementos_activos.append(area)
	
	# Si salió charco de aceite, pone una señal de peligro un poco antes
	if "charco_aceite" in ruta_txt:
		var aviso = Sprite2D.new()
		aviso.texture = load("res://images/06_Senales_UI/senal_peligro_1.png")
		aviso.scale = Vector2(0.11, 0.11)
		aviso.z_index = 4
		aviso.position = Vector2(1110, y_elegido + 15) # En la banqueta, antes del aceite
		get_parent().add_child(aviso)
		elementos_activos.append(aviso)
