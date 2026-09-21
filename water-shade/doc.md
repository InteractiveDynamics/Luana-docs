# Água em código — water-shade

Anotações do shader de água que escrevi direto em código (`.gdshader`), diferente
do de neve, que montei no editor visual. Boa parte dos conceitos daqui eu
reaproveito pro ExoTerra.

Fonte: *(link do vídeo — preencher)*

O objetivo era uma superfície de água com movimento, refração e uns defeitos de
lente. Código completo em [`water_shader.gdshader`](water_shader.gdshader).

## vertex() vs fragment()

Um shader 3D roda em duas etapas na GPU:

- `vertex()` — roda pra cada vértice; mexe na forma e posição da malha.
- `fragment()` — roda pra cada pixel; define cor, brilho, transparência e como a
  luz bate.

Aqui usei só o `fragment()` — a ilusão de onda é feita só com cor, normal e
reflexo; a malha do plano nem se mexe.

No ExoTerra vou precisar dos dois: `vertex()` (ou dados vindos do C++) pra afundar
os vértices do chão e criar os sulcos das rodas, e `fragment()` pra cor da poeira e
a luz do Sol.

## Mapa de normais

Um normal map é uma textura onde o RGB não é cor, é direção (X, Y, Z). Ele engana
a luz, fazendo parecer que tem micro-relevo sem adicionar polígono nenhum.
Amostrei com `texture(sampler2D, UV)` um ruído (`FastNoiseLite`) configurado como
normal map.

Isso serve direto pro regolito: dá o aspecto áspero e poroso da areia lunar de
graça na GPU.

## Deslocamento de UV + escala de tempo

UV é o mapeamento 2D da textura sobre o objeto (vai de 0 a 1). Como a UV original
é fixa, pra mover a textura eu copiei ela e somei `sin`/`cos` do `TIME`. Um
`uniform time_scale` num slider controla a velocidade.

No ExoTerra dá pra usar isso pra deslocar marcas/poeira em sincronia com a
velocidade real do rover (que vem do C++).

## Textura de tela + refração

`SCREEN_TEXTURE` guarda o que já foi desenhado na tela antes deste shader. Usando
`SCREEN_UV` eu leio esse fundo e somo uma distorçãozinha do ruído nas coordenadas
de leitura — é isso que dá o efeito de refração da água.

## O código que vale anotar

Dois trechos que separei porque as ideias reaparecem no projeto.

### Aberração cromática (defeito de lente, de propósito)

Leio a textura separando os canais R, G e B com deslocamentos diferentes:

```glsl
float r = texture(sun_highlight, _uv + abberration_r).r;
float g = texture(sun_highlight, _uv + abberration_g).g;
float b = texture(sun_highlight, _uv + abberration_b).b;
```

Isso desalinha as cores de leve e imita uma falha de lente. Pro ExoTerra é útil de
verdade: as câmeras de navegação do rover sofrem com radiação e variação térmica
extrema (uns -130 a 120 °C), que deformam a lente e causam aberração cromática
real. Simular esse defeito de propósito vira um stress test pros algoritmos de
visão computacional do laboratório.

### soft_light sem `if` (branchless)

Pra mesclar as cores eu evitei `if`/`else` e usei `step()` + `mix()`:

```glsl
vec3 soft_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(
		2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
		sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), 
		limit
	);
}
```

Por que fugir do `if` numa GPU: ela processa os pixels em paralelo (SIMD). Se
metade dos pixels cai no `if` e metade no `else`, ela é obrigada a rodar os dois
caminhos e perde o paralelismo (divergência de branch). Com o `step()`, todo pixel
faz a mesma conta e o resultado (0 ou 1) só decide o peso do `mix()`. Isso poupa
milissegundos por frame — exatamente o tipo de economia que ajuda a segurar o FTR
quando a ExoPhysics estiver rodando junto.

---

**Minhas notas**

- No código tem `NORMAL_MAP = ...` seguido de `NORMAL *= 0.5`. Acho que esse
  `NORMAL *= 0.5` não faz o efeito que eu esperava; pra suavizar a intensidade das
  ondas o certo parece ser `NORMAL_MAP_DEPTH`. *(conferir)*
- O que me confundiu: *(preencher)*
- Como resolvi: *(preencher)*
