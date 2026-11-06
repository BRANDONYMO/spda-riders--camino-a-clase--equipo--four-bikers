SPDA RIDERS: CAMINO A CLASE
PAQUETE DE ASSETS SEPARADOS PARA GODOT

ESTRUCTURA
00_Referencia              -> lámina original de referencia
01_Jugador                 -> Idle, Run, Jump y Fall; cada carpeta trae Sheet + frames individuales
02_Obstaculos_NPCs         -> perro, peatón, peatón ebrio, maguey y automóvil
03_Objetos_Interactivos    -> gasolinera, galón, moneda opcional y turbo
04_TileMap_Pista           -> asfalto, tierra/césped, piedra, rampa, plataformas y obstáculos de pista
05_Entorno_Decoracion      -> elementos del pueblo y transición semiurbana
06_Senales_UI              -> señales, vidas y medidores
07_Fondos                  -> mañana, mediodía, tarde, atardecer, noche y media noche

RECOMENDACIÓN DE USO EN GODOT
- Player/Rider: CharacterBody2D + Sprite2D/AnimatedSprite2D + CollisionShape2D.
- Perro, peatón, peatón ebrio, maguey y automóvil: Area2D + CollisionShape2D si al contacto deben restar una oportunidad.
- Galón de gasolina: Area2D + CollisionShape2D; al recogerlo aumenta gasolina y desaparece.
- Objetos puramente decorativos (árboles, casas, postes, iglesia, etc.): normalmente Sprite2D sin colisión.
- Tiles de carretera/piso: TileMapLayer/TileSet; las colisiones se configuran solo en tiles que deban bloquear o delimitar.
- Señales y HUD: Sprite2D o Control/TextureRect según dónde los uses.
- La universidad/meta puede manejarse con Area2D al final del recorrido para cambiar a la pantalla de victoria.

NOTA
La moneda aparece en la lámina visual como asset opcional, pero no forma parte de la mecánica principal descrita en el GDD.
