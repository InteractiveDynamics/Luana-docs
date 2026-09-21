@tool
extends MeshInstance3D
## Gera a malha 3D do terreno a partir de um heightmap
## (imagem em tons de cinza: claro = alto, escuro = baixo).
## É o pipeline do Mês 05 do plano: relevo -> malha.

## Imagem de relevo. Deixe VAZIO para usar um relevo de teste (ruído).
## Depois, arraste aqui o PNG do DEM da LRO para usar o relevo lunar real.
@export var heightmap: Texture2D : set = _set_heightmap
## Tamanho do terreno no mundo (eixos X e Z), em metros.
@export var terrain_size: float = 20.0 : set = _set_size
## Altura máxima do relevo, em metros.
@export var height_scale: float = 4.0 : set = _set_height
## Resolução da malha (divisões por lado). Mais = mais detalhe (e mais custo).
@export var subdivisions: int = 128 : set = _set_subdiv
## Marque/desmarque para regenerar dentro do editor.
@export var regenerate: bool = false : set = _set_regenerate

func _set_heightmap(v: Texture2D) -> void:
	heightmap = v
	_rebuild()

func _set_size(v: float) -> void:
	terrain_size = v
	_rebuild()

func _set_height(v: float) -> void:
	height_scale = v
	_rebuild()

func _set_subdiv(v: int) -> void:
	subdivisions = max(1, v)
	_rebuild()

func _set_regenerate(_v: bool) -> void:
	_rebuild()

func _ready() -> void:
	generate()

func _rebuild() -> void:
	# Só regenera se o nó já estiver na cena (evita erro ao carregar).
	if is_inside_tree():
		generate()

func generate() -> void:
	var img := _get_heightmap_image()
	if img == null:
		push_warning("Sem heightmap disponível.")
		return

	var iw := img.get_width()
	var ih := img.get_height()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := terrain_size / float(subdivisions)
	var half := terrain_size * 0.5

	# 1) Grade de vértices. A altura (Y) vem do brilho do pixel do heightmap.
	for z in range(subdivisions + 1):
		for x in range(subdivisions + 1):
			var u := float(x) / float(subdivisions)
			var v := float(z) / float(subdivisions)
			var px := int(u * float(iw - 1))
			var py := int(v * float(ih - 1))
			var h := img.get_pixel(px, py).r  # canal vermelho = cinza (0..1)
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(x * step - half, h * height_scale, z * step - half))

	# 2) Triângulos: dois por célula da grade.
	var row := subdivisions + 1
	for z in range(subdivisions):
		for x in range(subdivisions):
			var i := z * row + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + row)
			st.add_index(i + 1)
			st.add_index(i + row + 1)
			st.add_index(i + row)

	# Normais e tangentes são necessárias pra luz bater certo no relevo.
	st.generate_normals()
	st.generate_tangents()
	mesh = st.commit()

func _get_heightmap_image() -> Image:
	if heightmap != null:
		return heightmap.get_image()
	# Relevo de teste com ruído, pra funcionar sem imagem externa.
	var n := FastNoiseLite.new()
	n.frequency = 0.012
	n.fractal_octaves = 5
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in range(size):
		for x in range(size):
			var val := n.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			img.set_pixel(x, y, Color(val, val, val))
	return img
