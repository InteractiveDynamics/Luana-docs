// Neve interativa: o chão afunda onde a "trilha" marca (pegadas/rastros).
// A trilha é uma textura atualizada por código conforme a bola se move.
// Isto é o embrião do Mês 08: a roda do rover deformando o regolito.
shader_type spatial;

uniform sampler2D trilha : hint_default_black; // 0 = intacto, 1 = pressionado
uniform float profundidade : hint_range(0.0, 2.0) = 0.6;
uniform vec4 cor_neve : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 cor_comprimida : source_color = vec4(0.68, 0.70, 0.80, 1.0);

varying float v_t;

void vertex() {
	// Lê a trilha e afunda o vértice onde algo passou.
	float t = texture(trilha, UV).r;
	v_t = t;
	VERTEX.y -= t * profundidade;
}

void fragment() {
	// Neve comprimida fica um pouco mais escura/azulada.
	ALBEDO = mix(cor_neve.rgb, cor_comprimida.rgb, v_t);
	ROUGHNESS = 0.7;
}
