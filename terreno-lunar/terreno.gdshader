// Pintura do terreno por inclinação (slope), reusando a lógica do snow-shade:
// - áreas planas (viradas pro céu)   -> regolito claro (poeira acumulada)
// - encostas íngremes (crateras)     -> rocha escura exposta (leito rochoso)
//
// A máscara é o produto escalar da normal (no espaço do mundo) com o "pra cima".
shader_type spatial;

uniform vec4 cor_plano : source_color = vec4(0.62, 0.60, 0.57, 1.0);   // regolito
uniform vec4 cor_encosta : source_color = vec4(0.22, 0.21, 0.20, 1.0); // rocha
uniform float limiar : hint_range(0.0, 1.0) = 0.75;        // quão plano vira poeira
uniform float suavizacao : hint_range(0.001, 0.5) = 0.15;  // borda entre os dois
uniform sampler2D ruido;
uniform float ruido_escala : hint_range(1.0, 50.0) = 12.0;
uniform float ruido_forca : hint_range(0.0, 0.5) = 0.15;

void fragment() {
	// A NORMAL vem em espaço de visão; converto pro espaço do mundo,
	// senão o "pra cima" muda quando a câmera gira.
	vec3 n_mundo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Inclinação: 1 = plano virado pro céu, 0 = parede vertical.
	float inclinacao = dot(n_mundo, vec3(0.0, 1.0, 0.0));

	// Ruído pra quebrar a borda perfeita entre poeira e rocha.
	float r = texture(ruido, UV * ruido_escala).r;
	inclinacao += (r - 0.5) * ruido_forca;

	// Máscara: poeira onde é plano, rocha onde é íngreme.
	float mascara = smoothstep(limiar - suavizacao, limiar + suavizacao, inclinacao);

	ALBEDO = mix(cor_encosta.rgb, cor_plano.rgb, mascara);
	ROUGHNESS = 1.0; // regolito não é brilhante
}
