# Neve por inclinação — snow-shade

Anotações do shader de acúmulo de neve que montei no editor visual do Godot
(o de nós, não em código). A ideia é o shader decidir sozinho onde cai neve e
onde fica rocha exposta, a partir da inclinação da superfície — sem pintar nada
à mão.

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

---

**Minhas notas**

- O que me confundiu: *(preencher)*
- Como resolvi: *(preencher)*
