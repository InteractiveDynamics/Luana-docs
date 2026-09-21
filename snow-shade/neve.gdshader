// Acúmulo de neve por inclinação (versão em código do shader visual do snow-shade).
// A mesma ideia serve pra POEIRA LUNAR depois: onde é plano, acumula; nas
// encostas, fica exposto.
//
//   normal virada pro céu (dot ~ 1) -> neve
//   parede vertical      (dot ~ 0) -> rocha
shader_type spatial;

uniform vec4 cor_neve : source_color = vec4(0.95, 0.96, 1.0, 1.0);
uniform vec4 cor_rocha : source_color = vec4(0.25, 0.24, 0.23, 1.0);
uniform float limiar : hint_range(0.0, 1.0) = 0.6;        // quão plano p/ acumular
uniform float suavizacao : hint_range(0.001, 0.5) = 0.1;
uniform sampler2D ruido;
uniform float ruido_escala : hint_range(1.0, 50.0) = 8.0;
uniform float ruido_forca : hint_range(0.0, 0.5) = 0.2;

void fragment() {
	// NORMAL vem em espaço de visão; converto pro mundo, senão o "pra cima"
	// muda quando a câmera gira.
	vec3 n_mundo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Acúmulo = alinhamento da superfície com o "pra cima".
	float acumulo = dot(n_mundo, vec3(0.0, 1.0, 0.0));

	// Ruído pra a borda entre neve e rocha não ficar perfeita.
	float r = texture(ruido, UV * ruido_escala).r;
	acumulo += (r - 0.5) * ruido_forca;

	float mascara = smoothstep(limiar - suavizacao, limiar + suavizacao, acumulo);

	ALBEDO = mix(cor_rocha.rgb, cor_neve.rgb, mascara);
	ROUGHNESS = mix(0.9, 0.5, mascara); // neve reflete um pouco mais que a rocha
}
