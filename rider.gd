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

var label_monedas_texto = Label.new()
var barra_gasolina = ProgressBar.new()
var label_vidas_texto = Label.new()
var label_turbo_estado = Label.new()

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
	# Recupera las vidas y monedas de la memoria si vienes de la pantalla de choque
	if get_tree().has_meta("vidas_guardadas"):
		vidas = get_tree().get_meta("vidas_guardadas")
	if get_tree().has_meta("monedas_guardadas"):
		monedas = get_tree().get_meta("monedas_guardadas")
		
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

func _process(delta):
	var velocidad_base = 650
	
	if tiene_turbo and (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_X)):
		tiempo_turbo = 3.0
		tiene_turbo = false
		label_turbo_estado.text = ": ¡TURBO ACTIVO!"
		
	if tiempo_turbo > 0:
		tiempo_turbo -= delta
		velocidad_base = 1100
		if tiempo_turbo <= 0:
			label_turbo_estado.text = ": SIN TURBO"

	var velocidad = 0
	
	if Input.is_action_pressed("ui_right"):
		velocidad = velocidad_base
		if anim_player.current_animation != "Run":
			anim_player.play("Run")
			
		gasolina -= delta * 1.0
		if gasolina <= 0:
			# Si se acaba la gasolina, manda directo a Game Over
			get_tree().set_meta("vidas_guardadas", 3)
			get_tree().set_meta("monedas_guardadas", 0)
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

	ajustar_tamano()

	if velocidad > 0 and fondo1 and fondo2:
		fondo1.position.x -= velocidad * delta
		fondo2.position.x -= velocidad * delta
		
		if fondo1.position.x <= -1152:
			fondo1.position.x = fondo2.position.x + 1152
		if fondo2.position.x <= -1152:
			fondo2.position.x = fondo1.position.x + 1152

		for elem in elementos_activos:
			if is_instance_valid(elem):
				elem.position.x -= velocidad * delta
				if elem.position.x < -100:
					elem.queue_free()
					elementos_activos.erase(elem)

	if velocidad > 0:
		tiempo_spawn += delta
		if tiempo_spawn >= 1.6:
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

func crear_elemento_aleatorio():
	var area = Area2D.new()
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
	
	var y_elegido = carriles[randi() % carriles.size()]
	area.position = Vector2(1200, y_elegido)
	
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
				# Resta 1 vida, la guarda en memoria y cambia a la escena
				vidas -= 1
				get_tree().set_meta("vidas_guardadas", vidas)
				
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

func ajustar_tamano():
	if sprite and sprite.texture:
		var ancho_frame = float(sprite.texture.get_width()) / float(sprite.hframes)
		if ancho_frame > 0:
			var escala = ancho_deseado / ancho_frame
			sprite.scale = Vector2(escala, escala)
