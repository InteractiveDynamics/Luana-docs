# Luana-docs

Anotações e estudos da minha iniciação científica (PIBIC) no LASE/COSMOS – UnB.

Meu plano de trabalho é o **ExoTerra**: a ferramenta de visualização 3D em tempo
real do ambiente lunar, feita no Godot. Enquanto aprendo o motor e a parte
gráfica, vou guardando aqui o que estudo e testo.

## Anotações

- [water-shade](water-shade/doc.md) — shader de água: deslocamento de UV,
  mapa de normais, textura de tela (refração) e aberração cromática.
- [snow-shade](snow-shade/doc.md) — máscara de acúmulo por inclinação
  (produto escalar da normal com o "para cima"), mix rocha/neve e ruído.

## Ferramentas

- Godot 4.7
- GLSL (shaders)

## Organização

Cada pasta é um tópico de estudo com um `doc.md` explicando o conceito e, quando
faz sentido, o código do shader e um print do resultado.
