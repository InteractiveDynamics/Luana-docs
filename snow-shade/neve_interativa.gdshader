// Neve interativa: o chão afunda onde a "trilha" marca (pegadas/rastros).
// A trilha é uma textura atualizada por código conforme a bola se move.
// Isto é o embrião do Mês 08: a roda do rover deformando o regolito.
shader_type spatial;

uniform sampler2D trilha : hint_default_black; // 0 = intacto, 1 = pressionado
uniform float profundidade : hint_range(0.0, 2.0) = 0.6;
uniform float tamanho_plano = 20.0;      // igual ao size do PlaneMesh
uniform float resolucao_trilha = 256.0;  // igual à resolução do mapa (script)
uniform vec4 cor_neve : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 cor_comprimida : source_color = vec4(0.5, 0.52, 0.58, 1.0);

varying float v_t;

void vertex() {
	float e = 1.0 / resolucao_trilha;
	float t = texture(trilha, UV).r;
	float tx = texture(trilha, UV + vec2(e, 0.0)).r; // vizinho em X
	float tz = texture(trilha, UV + vec2(0.0, e)).r; // vizinho em Z
	v_t = t;

	// Afunda o vértice onde algo passou.
	VERTEX.y -= t * profundidade;

	// Recalcula a normal pela inclinação da trilha, pra a cova ter sombra.
	float passo = e * tamanho_plano; // distância entre vizinhos, em metros
	float sx = -(tx - t) * profundidade / passo;
	float sz = -(tz - t) * profundidade / passo;
	NORMAL = normalize(vec3(-sx, 1.0, -sz));
}

void fragment() {
	// Neve comprimida fica mais escura, criando contraste com a neve intacta.
	ALBEDO = mix(cor_neve.rgb, cor_comprimida.rgb, v_t);
	ROUGHNESS = 0.7;
}
