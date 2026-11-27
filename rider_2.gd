extends CharacterBody2D

var carriles = [510, 580]
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

# --- AUDIO ---
var sfx_moto = AudioStreamPlayer.new()
var sfx_moto_normal = AudioStreamPlayer.new()
var sfx_moneda = AudioStreamPlayer.new()

# -------------------------------------------------
# --- VARIABLES DE META Y DISTANCIA ---
# -------------------------------------------------
var distancia_recorrida = 0.0
var distancia_meta = 20000.0
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

# --- AQUÍ ESTÁN TUS NUEVOS OBSTÁCULOS PARA EL NIVEL 2 ---
var rutas_obstaculos = [
	"res://images/02_Obstaculos_NPCs/maguey1.png",
	"res://images/06_Senales_UI/tronco_1.png",
	"res://images/03_Objetos_Interactivos/roca_obstaculo.png",
	"res://images/03_Objetos_Interactivos/cono_trafico.png",
	# Sprites de interacción añadidos
	"res://images/sprites run/ciclista run.png",
	"res://images/sprites run/trabajador obra run.png",
	"res://images/sprites run/vaca run.png",
	"res://images/sprites run/vendedor run.png"
]

var rutas_coleccionables = [
	"res://images/03_Objetos_Interactivos/moneda_coleccionable.png",
	"res://images/03_Objetos_Interactivos/galon_gasolina.png",
	"res://images/03_Objetos_Interactivos/turbo_icono.png"
]

func _ready():
	# Guardamos en memoria que estamos en el Nivel 2 por si choca o pierde
	get_tree().set_meta("nivel_actual", "res://nivel_2.tscn")
	
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
	configurar_audio()

func configurar_audio():
	sfx_moto.stream = load("res://audio/motocontinuo.mp3")
	sfx_moto.volume_db = -6.0
	add_child(sfx_moto)
	
	sfx_moto_normal.stream = load("res://audio/motonormal.mp3")
	sfx_moto_normal.volume_db = -8.0
	add_child(sfx_moto_normal)
	
	sfx_moneda.stream = load("res://audio/monedarecolectada.mp3")
	add_child(sfx_moneda)

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
		if sfx_moto.playing:
			sfx_moto.stop()
		if sfx_moto_normal.playing:
			sfx_moto_normal.stop()
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
			if sfx_moto.playing:
				sfx_moto.stop()
			if sfx_moto_normal.playing:
				sfx_moto_normal.stop()
			anim_player.play("Idle")
			finalizar_nivel_utvm()
		ajustar_tamano()
		return
		
	var velocidad_base = 650
	
	if tiene_turbo and (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_X)):
		tiempo_turbo = 3.0
		tiene_turbo = false
		label_turbo_estado.text = ": ¡TURBO ACTIVO!"
		sfx_moto.play()
		
	if tiempo_turbo > 0:
		tiempo_turbo -= delta
		velocidad_base = 1100
		if tiempo_turbo <= 0:
			label_turbo_estado.text = ": SIN TURBO"
			sfx_moto.stop()

	var velocidad = 0
	
	if Input.is_action_pressed("ui_right"):
		velocidad = velocidad_base
		if anim_player.current_animation != "Run":
			anim_player.play("Run")
			
		gasolina -= delta * 1.0
		if gasolina <= 0:
			get_tree().set_meta("vidas_guardadas", 3)
			get_tree().set_meta("monedas_guardadas", 0)
			get_tree().set_meta("nivel_actual", "res://nivel_2.tscn")
			get_tree().change_scene_to_file("res://game_over.tscn")
		barra_gasolina.value = gasolina
		
	elif Input.is_action_pressed("ui_left"):
		velocidad = 250
		if anim_player.current_animation != "Run":
			anim_player.play("Run")
	else:
		velocidad = 0
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")

	if velocidad > 0 and tiempo_turbo <= 0:
		if not sfx_moto_normal.playing:
			sfx_moto_normal.play()
	else:
		if sfx_moto_normal.playing:
			sfx_moto_normal.stop()

	ajustar_tamano()

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
				
			# Entra la única fachada de la UTVM (utvm2.png) junto con la meta
			if distancia_recorrida >= (distancia_meta - 1152.0) and not recta_final_creada:
				generar_recta_final_utvm()
				recta_final_creada = true

		# --- EXPLICACIÓN PARA EL PROFESOR: MOVIMIENTO INDEPENDIENTE ---
		for elem in elementos_activos:
			if is_instance_valid(elem):
				# Por defecto, los objetos se acercan a la misma velocidad a la que tú aceleras
				var velocidad_movimiento = velocidad 
				
				# LÓGICA DE MOVIMIENTO:
				# Preguntamos: ¿Este elemento tiene la etiqueta "velocidad_propia" (es un NPC)?
				if elem.has_meta("velocidad_propia"):
					# Al restarle esta velocidad, el personaje avanza hacia adelante en el eje X
					# relativo a los objetos estáticos del fondo.
					velocidad_movimiento -= elem.get_meta("velocidad_propia")
					
				elem.position.x -= velocidad_movimiento * delta
				
				# No borramos la fachada de la UTVM para que cubra todo el fondo al llegar
				if not elem.has_meta("es_fachada_utvm") and elem.position.x < -150:
					elem.queue_free()
					elementos_activos.erase(elem)

		# Si el borde derecho de utvm2.png ya llegó al borde derecho de la pantalla, frenamos el fondo
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
		if tiempo_spawn >= 0.6: 
			tiempo_spawn = 0.0
			crear_elemento_aleatorio()

	if Input.is_action_just_pressed("ui_up"):
		carril_actual = 0
		position.y = carriles[carril_actual]
		anim_player.play("Jump")
		ajustar_tamano()
		
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
	# Ajusta 455.0 si quieres subirla o bajarla un poco sobre la orilla de la pista
	sprite_senal.position = Vector2(1220.0, 455.0)
	
	get_parent().add_child(sprite_senal)
	elementos_activos.append(sprite_senal)
# ---------------------------------------------------

# ---------------------------------------------------
# --- FUNCIÓN QUE CREA LA FACHADA UTVM Y LA META ---
# ---------------------------------------------------
func generar_recta_final_utvm():
	# 1. Única imagen de la fachada de la UTVM (utvm2.png) alineada al borde del fondo actual
	var tex_utvm = load("res://images/07_Fondos/utvm2.png")
	var escala_y = 656.0 / float(tex_utvm.get_height())
	ancho_utvm_escalado = float(tex_utvm.get_width()) * escala_y
	
	# Empata exactamente con el borde derecho del fondo que viene entrando para evitar cortes
	var x_inicio_utvm = max(fondo1.position.x, fondo2.position.x) + 1152.0
	
	var nodo_utvm = Node2D.new()
	nodo_utvm.z_index = 1
	nodo_utvm.position = Vector2(x_inicio_utvm, -8.0)
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

func crear_elemento_aleatorio():
	var area = Area2D.new()
	area.z_index = 4
	var es_coleccionable = randi() % 2 == 0
	
	var ruta_txt = ""
	if es_coleccionable:
		ruta_txt = rutas_coleccionables[randi() % rutas_coleccionables.size()]
	else:
		ruta_txt = rutas_obstaculos[randi() % rutas_obstaculos.size()]
		
	var sprite_elem = Sprite2D.new()
	sprite_elem.texture = load(ruta_txt)
	
	var es_animado = false
	var frames_totales = 8 
	
	# VARIABLE PARA LA VELOCIDAD DEL PERSONAJE
	var velocidad_npc = 0 
	
	if "ciclista run" in ruta_txt:
		es_animado = true
		sprite_elem.scale = Vector2(0.20, 0.20) 
		sprite_elem.position.y = 8 
		# AQUÍ LE DECIMOS QUÉ TAN RÁPIDO CORRE (200 es rápido)
		velocidad_npc = 200 
	elif "trabajador obra run" in ruta_txt:
		es_animado = true
		sprite_elem.scale = Vector2(0.18, 0.18)
		sprite_elem.position.y = 8
		velocidad_npc = 150 
	elif "vaca run" in ruta_txt:
		es_animado = true
		sprite_elem.scale = Vector2(0.20, 0.20)
		sprite_elem.position.y = 8
		velocidad_npc = 80 
	elif "vendedor run" in ruta_txt:
		es_animado = true
		sprite_elem.scale = Vector2(0.18, 0.18)
		sprite_elem.position.y = 8
		velocidad_npc = 120 
	elif "maguey" in ruta_txt:
		sprite_elem.scale = Vector2(0.06, 0.06) 
		sprite_elem.position.y = 15 
	elif "tronco" in ruta_txt:
		sprite_elem.scale = Vector2(0.14, 0.14) 
		sprite_elem.position.y = 15 
	else:
		sprite_elem.scale = Vector2(0.06, 0.06)
		sprite_elem.position.y = 15 
	
	# --- EXPLICACIÓN PARA EL PROFESOR: ASIGNACIÓN DE VELOCIDAD ---
	# Si la velocidad_npc es mayor a 0 (es un NPC interactivo)
	if velocidad_npc > 0:
		# Usamos set_meta para guardarle la velocidad específica al área instanciada
		area.set_meta("velocidad_propia", velocidad_npc)

	if es_animado:
		sprite_elem.hframes = frames_totales
		sprite_elem.frame = 0
		
		var timer = Timer.new()
		timer.wait_time = 0.08
		timer.autostart = true
		timer.timeout.connect(func():
			if is_instance_valid(sprite_elem):
				sprite_elem.frame = (sprite_elem.frame + 1) % frames_totales
		)
		area.add_child(timer)
		
	area.add_child(sprite_elem)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 22.0
	col.shape = shape
	area.add_child(col)
	
	var y_elegido = carriles[randi() % carriles.size()]
	area.position = Vector2(1200, y_elegido)
	
	area.body_entered.connect(func(body):
		if body == self:
			if es_coleccionable:
				if "moneda" in ruta_txt:
					sfx_moneda.play()
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
				get_tree().set_meta("nivel_actual", "res://nivel_2.tscn")
				
				if vidas > 0:
					get_tree().change_scene_to_file("res://choque.tscn")
				else:
					get_tree().set_meta("vidas_guardadas", 3)
					get_tree().set_meta("monedas_guardadas", 0)
					get_tree().change_scene_to_file("res://game_over.tscn")
	)
	
	get_parent().add_child(area)
	elementos_activos.append(area)

func ajustar_tamano():
	if sprite and sprite.texture:
		var ancho_frame = float(sprite.texture.get_width()) / float(sprite.hframes)
		if ancho_frame > 0:
			var escala = ancho_deseado / ancho_frame
			sprite.scale = Vector2(escala, escala)
