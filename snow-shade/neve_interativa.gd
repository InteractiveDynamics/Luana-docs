extends Node3D
## Neve interativa: mantém um "mapa de trilha" (uma imagem) que registra por onde
## a bola passou. A cada frame carimba a posição da bola na imagem e envia pro
## shader, que afunda a malha ali. O rastro é persistente (a imagem nunca zera).
##
## Depois, a "bola" vira a roda do rover, e o carimbo vem da física da ExoPhysics.

@export var agente: Node3D              # a bola que deixa o rastro
@export var tamanho_plano: float = 20.0 # tamanho do plano (X e Z), em metros
@export var resolucao: int = 256        # resolução do mapa de trilha
@export var raio_pincel: float = 0.05   # tamanho da pegada (em UV, 0..1)
@export var forca: float = 1.0          # o quanto cada passagem afunda

var _img: Image
var _tex: ImageTexture

@onready var _neve: MeshInstance3D = $Neve

func _ready() -> void:
	# Cria o mapa de trilha vazio (tudo intacto).
	_img = Image.create(resolucao, resolucao, false, Image.FORMAT_RF)
	_img.fill(Color(0.0, 0.0, 0.0))
	_tex = ImageTexture.create_from_image(_img)
	var mat := _neve.material_override as ShaderMaterial
	if mat:
		mat.set_shader_parameter("trilha", _tex)

func _process(_delta: float) -> void:
	if agente == null:
		return
	# Move a bola em círculo, só pra demonstrar o rastro.
	var t := float(Time.get_ticks_msec()) / 1000.0
	agente.position = Vector3(cos(t) * 6.0, agente.position.y, sin(t) * 6.0)
	_carimbar(agente.global_position)

func _carimbar(pos_mundo: Vector3) -> void:
	# Mapeia a posição XZ do mundo para as coordenadas UV do plano.
	var u := pos_mundo.x / tamanho_plano + 0.5
	var v := pos_mundo.z / tamanho_plano + 0.5
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return

	var cx := int(u * float(resolucao))
	var cy := int(v * float(resolucao))
	var raio_px := int(raio_pincel * float(resolucao))
	if raio_px < 1:
		raio_px = 1

	for y in range(cy - raio_px, cy + raio_px + 1):
		for x in range(cx - raio_px, cx + raio_px + 1):
			if x < 0 or y < 0 or x >= resolucao or y >= resolucao:
				continue
			var d := Vector2(float(x - cx), float(y - cy)).length() / float(raio_px)
			if d > 1.0:
				continue
			# Acumula (não zera): pegada mais funda no centro, some na borda.
			var atual := _img.get_pixel(x, y).r
			var novo: float = min(1.0, atual + (1.0 - d) * forca)
			_img.set_pixel(x, y, Color(novo, 0.0, 0.0))

	_tex.update(_img)
