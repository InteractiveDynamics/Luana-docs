# Pintura do terreno por inclinação — terreno-lunar

Depois de gerar a malha do terreno a partir do heightmap, o próximo passo foi
pintar ela sozinha: regolito claro nas partes planas e rocha escura nas encostas.
Reusei a mesma ideia do [snow-shade](../snow-shade/doc.md) — só troquei "neve/rocha"
por "poeira/rocha lunar".

Fonte: reaproveita o snow-shade + a técnica de slope do vídeo do Sebastian Lague
(*Procedural Moons and Planets*). Link: *(preencher)*

## A ideia

A máscara é o **produto escalar da normal da superfície com o vetor "pra cima"**
`(0, 1, 0)`:

- perto de `1` → o ponto está virado pro céu (plano) → poeira
- perto de `0` → parede vertical (encosta de cratera) → rocha exposta

O `smoothstep` transforma esse valor numa máscara suave e o `mix` escolhe a cor.
Um ruído é somado antes pra a borda entre poeira e rocha não ficar uma linha
perfeita e artificial.

O detalhe que me pegou: a `NORMAL`, no shader, vem em **espaço de visão**, não do
mundo. Se eu usasse ela direto, o "pra cima" mudaria quando a câmera girasse. Por
isso converto pro espaço do mundo com a `INV_VIEW_MATRIX`:

```glsl
vec3 n_mundo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
float inclinacao = dot(n_mundo, vec3(0.0, 1.0, 0.0));
```

## Como isso se encaixa na pesquisa

Isso é do meu **Mês 06** (shaders da superfície lunar) e dá suporte ao **Mês 05**
(o terreno da LRO). Não é enfeite, por dois motivos:

1. **Reflete a geomorfologia lunar real.** O regolito fino tende a escorregar e se
   acumular em bacias e áreas planas, enquanto as paredes íngremes das crateras
   expõem o leito rochoso. Pintar por inclinação codifica esse comportamento em vez
   de eu pintar textura à mão.
2. **Gera imagem realista pros testes.** O ExoTerra existe pra validar algoritmos de
   navegação autônoma e visão computacional, que "enxergam" o simulador por câmera.
   Contraste e textura coerentes com a Lua real deixam esse teste mais fiel.

E, sendo automático (data-driven), escala pro terreno grande da LRO sem trabalho
manual: o mesmo shader pinta qualquer relevo que eu carregar.

## Referências

- BARKER, M. K. et al. A new lunar digital elevation model from the Lunar Orbiter
  Laser Altimeter and SELENE Terrain Camera. *Icarus*, v. 273, p. 346-355, 2016.
- LUCEY, P. et al. Understanding the Lunar Surface and Space-Moon Interactions.
  *Reviews in Mineralogy and Geochemistry*, v. 60, 2006. *(conferir dados da citação)*
- LAGUE, S. Coding Adventure: Procedural Moons and Planets. YouTube (devlog).
- GODOT ENGINE. Godot Engine Documentation — Shading Language. Disponível em:
  https://docs.godotengine.org. Acesso em: 2026.

## Minhas notas

- O que me confundiu: *(preencher)*
- Como resolvi: *(preencher)*
