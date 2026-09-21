# Neve por inclinação — snow-shade

Anotações do shader de acúmulo de neve. Montei primeiro no editor visual do Godot
(o de nós); aqui no repo está a versão em código ([`neve.gdshader`](neve.gdshader))
com a mesma lógica, e uma cena ([`neve.tscn`](neve.tscn)) que já tem neve caindo.
A ideia é o shader decidir sozinho onde cai neve e onde fica rocha exposta, a
partir da inclinação da superfície — sem pintar nada à mão.

Fonte: *(link do vídeo — preencher)*

Lógica no geral: pra cada ponto da malha eu calculo o quanto ele está virado pra
cima. Quanto mais virado pro céu, mais neve; quanto mais vertical, mais rocha.

## Espaço local vs. espaço do mundo

As normais (os vetores que dizem pra onde a superfície aponta) vêm em espaço
local por padrão. O problema é que, no espaço local, se o objeto gira o "pra cima"
gira junto — e aí a neve grudaria no lugar errado. Por isso converti a normal pro
espaço do mundo com o bloco Transform (matriz × vetor), onde o "pra cima" é
sempre o céu.

No ExoTerra isso importa porque, quando o rover inclinar numa rampa, é o espaço
do mundo que diz onde a poeira assenta — não o referencial do próprio robô.

## Produto escalar (dot) — a máscara

Fiz o produto escalar entre a normal (já no mundo) e o vetor (0, 1, 0). Com os
dois normalizados, o resultado diz o quão alinhados estão:

- `1` → superfície reta virada pro céu (branco na máscara → neve)
- `0` → parede vertical (preto → rocha)
- negativo → virado pra baixo

É exatamente o mesmo cálculo que vou usar pra luz do Sol sem atmosfera: dot
entre a normal do terreno e a direção do Sol; maior que zero, iluminado; zero ou
menos, sombra dura e preta.

## Mix (lerp) — misturar as texturas

O Mix pega a textura A (rocha) e a B (neve) e escolhe entre as duas por um peso.
Usei o resultado do dot como peso: onde deu 1, ele desenha neve; onde deu 0,
mantém a rocha.

No ExoTerra é assim que penso em mostrar o solo intacto virando solo deformado
— o C++ manda um mapa de peso e o shader mistura as duas texturas.

## Ruído (FastNoiseLite)

Multipliquei um ruído em cima do dot pra máscara não ficar com uma borda
perfeita e artificial. Dá aquelas falhas e reentrâncias que parecem naturais.
O regolito também não se acumula em linha reta, então o ruído serve pra dar a
granularidade imperfeita do solo lunar.

## Neve caindo (partículas)

Além da pintura, a cena tem neve caindo de verdade, com um nó `GPUParticles3D`.
As partículas nascem numa caixa acima da cena e caem com gravidade suave; cada
floco é um quad branco pequeno em billboard (sempre virado pra câmera).

Isso é o embrião da **poeira lunar**: a mesma mecânica de partículas na GPU vai
servir pra poeira/regolito ejetado pela roda do rover. A diferença é que, na Lua,
não tem ar — a poeira não flutua nem desacelera como floco de neve; ela sobe e cai
em trajetória balística e ainda sofre carga eletrostática do vento solar. Então eu
reaproveito a ideia visual, mas os parâmetros (gravidade, arrasto, tempo de vida)
mudam pra bater com a física lunar.

## Como isso se encaixa na pesquisa

É do meu Mês 06 (shaders da superfície) e prepara o terreno pros meses de
deformação (Mês 08), quando a roda vai levantar poeira. Pintar por inclinação e
simular partículas dá fidelidade visual pros testes de navegação e visão
computacional do ExoTerra — que é pra isso que o simulador existe.

## Referências

- COLWELL, J. E. et al. Lunar surface: Dust dynamics and regolith mechanics.
  *Reviews of Geophysics*, v. 45, 2007. *(conferir dados da citação)*
- STUBBS, T. J. et al. A dynamic fountain model for lunar dust. *Advances in Space
  Research*, v. 37, 2006. *(conferir dados da citação)*
- GODOT ENGINE. Godot Engine Documentation — Particle Systems / Shading Language.
  Disponível em: https://docs.godotengine.org. Acesso em: 2026.

---

**Minhas notas**

- O que me confundiu: *(preencher)*
- Como resolvi: *(preencher)*
