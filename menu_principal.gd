extends Control

func _ready():
	# Asegurarnos de que el mouse sea visible para poder darle clic a los botones
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_btn_nivel_1_pressed():
	# Reiniciamos las vidas y monedas desde cero por si acaso, y cargamos el nivel 1
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://nivel_1.tscn")

func _on_btn_nivel_2_pressed():
	# Reiniciamos las vidas y monedas desde cero por si acaso, y cargamos el nivel 1
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://nivel_2.tscn")
	

func _on_btn_nivel_3_pressed():
	# Reiniciamos las vidas y monedas desde cero por si acaso, y cargamos el nivel 1
	get_tree().set_meta("vidas_guardadas", 3)
	get_tree().set_meta("monedas_guardadas", 0)
	get_tree().change_scene_to_file("res://nivel_3.tscn")

func _on_btn_salir_pressed():
	# Cierra el juego
	get_tree().quit()
