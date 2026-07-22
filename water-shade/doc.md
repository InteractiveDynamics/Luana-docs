# Anatomia de Shaders em Código (.gdshader)
**Análise teórica dos conceitos de processamento gráfico baseados no simulador de fluidos**

---

## 1. Funções de Vértice vs. Fragmento (Vertex vs. Fragment Functions)

### O Conceito:
O código de um shader 3D é dividido em duas etapas fundamentais que rodam diretamente na placa de vídeo (GPU) de forma paralela:
* **`vertex()`:** É uma função executada para cada **vértice geométrico** visível do modelo 3D. Serve para alterar a forma física, posição e deformação da malha.
* **`fragment()`:** É executada para cada **pixel** que o objeto ocupa na tela. Serve para definir a cor final, o brilho, a transparência e como a luz rebate naquele ponto.

### No tutorial:
Focamos na função `fragment()`, criando a ilusão visual de movimento de ondas alterando apenas as cores, normais e reflexos dos pixels, sem modificar a geometria real do plano tridimensional.

### Por que importa para o projeto?
* **Deformação do Solo:** Provavelmente usaremos as duas! Na função `vertex()`, teremos equações (ou dados em C++) para **mudar os vértices do chão**, criando fisicamente os buracos e sulcos das rodas do rover no regolito. Na função `fragment()`, calcularemos a cor cinza da poeira e o comportamento da luz do Sol incidindo sobre o solo.

---

## 2. Mapas de Normais (Normal Mapping) e Amostragem (Sampling)

### O Conceito:
Um mapa de normais (`Normal Map`) é uma textura colorida (geralmente azulada/roxa) onde os canais de cor RGB não representam cores, mas sim vetores de direção $(X, Y, Z)$. Ele engana o motor de renderização, fazendo a luz rebater como se o objeto tivesse micro-relevos e detalhes, sem precisar gastar desempenho adicionando milhões de polígonos reais na malha.

### No tutorial:
Foi utilizada a função `texture(sampler2D, UV)` para amostrar (ler) os dados de uma textura de ruído gerada pelo próprio motor da Godot (`FastNoiseLite`) configurada especificamente para agir como um mapa de normais.

### Por que importa para o projeto?
* **Granularidade do Regolito Lunar:** A areia da Lua é cheia de pedrinhas e micro-texturas ásperas. Podemos usar um mapa de normais procedural para dar o aspecto rugoso, poroso e realista ao solo lunar de forma rápida na GPU.

---

## 3. Deslocamento de Coordenadas UV e Escala de Tempo (UV Offset & Time Scale)

### O Conceito:
As coordenadas **UV** são um sistema de mapeamento 2D que diz como uma textura deve ser "vestida" sobre um objeto 3D, variando de `0` a `1` nos eixos horizontal (U) e vertical (V). Como as coordenadas originais são constantes, para mover uma textura é necessário criar uma cópia dessa variável e somar valores a ela ao longo do tempo.

### No tutorial:
Criamos uma variável de UV customizada e adicionamos funções trigonométricas (`sin` e `cos`) multiplicadas pela variável interna `TIME` da Godot. Ele também criou um parâmetro `uniform float time_scale` controlado por um slider para ajustar a velocidade do movimento.

### Por que importa para o projeto?
* **Telemetria de Movimento do Rover:** Quando o robô estiver se deslocando pelas crateras, as rodas vão girar e interagir com o chão. Usaremos o deslocamento de UVs baseado no tempo e na velocidade real do robô (enviada pelo código em C++) para fazer efeitos visuais de poeira ou marcas de pneu se deslocarem sob o veículo de forma sincronizada com a física.

---

## 4. Textura de Tela e Refração (Screen Texture & Screen UV)

### O Conceito:
A `SCREEN_TEXTURE` é um buffer especial que armazena a imagem de tudo o que já foi desenhado na tela antes do shader atual ser processado. Usar os valores de `SCREEN_UV` (as coordenadas dos pixels em relação à tela cheia) permite capturar o cenário de fundo e aplicar distorções matemáticas nele.

### No tutorial:
Para simular a transparência e a refração da água sem perder os reflexos e brilhos da superfície, usamos a dica de textura de tela (`hint_screen_texture`). Somamos pequenas distorções do mapa de ruído às coordenadas de leitura da tela, gerando o efeito visual de distorção de luz (refração).

### Por que importa para o projeto?
* **Sensores de Câmeras e Aberração Cromática:** No final do vídeo, o instrutor adicionou "Aberração Cromática" separando os canais RGB com pequenos offsets. Isso é de extrema importância pois os algoritmos de navegação autônoma do robô vão ler o simulador através de sensores de câmeras digitais reais. Simular imperfeições óticas de lentes, poeira na câmera e distorções na imagem capturada ajuda a testar se os algoritmos do laboratório são robustos o suficiente para falhas do mundo real.

## 5. Análise dos códigos

Abaixo estão detalhados os dois principais mecanismos implementados no código do shader que possuem aplicação direta nas metas de validação de sensores e otimização computacional do projeto.

---

### A. Simulação de Artefatos Ópticos: Decomposição de Canais e Aberração Cromática

#### Mecanismo no Código:
O shader realiza a leitura da textura de amostragem separando os componentes de cor primários através das variáveis `abberration_r`, `abberration_g` e `abberration_b`. Ao adicionar pequenos deslocamentos vetoriais (`vec2`) independentes nas coordenadas de leitura de cada canal, o sistema reconstrói o pixel através da amostragem defasada dos canais Vermelho (R), Verde (G) e Azul (B).

```glsl
float r = texture(sun_highlight, _uv + abberration_r).r;
float g = texture(sun_highlight, _uv + abberration_g).g;
float b = texture(sun_highlight, _uv + abberration_b).b;
```

#### Relevância Científica para o Ambiente Lunar:
Em missões espaciais, as câmeras de navegação óptica e os sensores computacionais dos rovers não operam em condições ideais. Eles estão expostos a fatores severos do ambiente lunar:
1. **Radiação Ionizante:** Degrada gradativamente os sensores CMOS/CCD e altera as propriedades de refração dos elementos ópticos de vidro.
2. **Variações Térmicas Extremas:** A oscilação brusca de temperatura (variando entre aproximadamente -130°C e 120°C) causa microdeformações mecânicas no conjunto de lentes, alterando ligeiramente o plano focal para diferentes comprimentos de onda da luz.

Esse fenômeno gera a **Aberração Cromática Real**. Dominar a manipulação de coordenadas RGB diretamente na GPU permite introduzir de forma controlada essas distorções ópticas e falhas de lentes induzidas pelo ambiente. Isso fornece um ambiente de teste realista e severo (*stress test*) para avaliar se os algoritmos de visão computacional e navegação autônoma desenvolvidos pelo laboratório mantêm a precisão sob degradação de imagem.

---

### B. Otimização de Pipeline Gráfico: Substituição de Condicionais por Funções Matemáticas (*Branching Prevention*)

#### Mecanismo no Código:
Para a execução da função de mesclagem `soft_light()`, evitou-se o uso de estruturas de controle de fluxo tradicionais da CPU (como `if` e `else`). Em seu lugar, foi adotada uma abordagem estritamente matemática combinando as funções nativas de GPU `step()` e `mix()`.

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

#### Relevância Científica para o Fator de Tempo Real (FTR):
A arquitetura de hardware das GPUs é projetada para o processamento massivo de dados em paralelo (SIMD - *Single Instruction, Multiple Data*). Quando um bloco condicional `if/else` é inserido em um shader, pode ocorrer o fenômeno de **Divergência de Branching (Ramificação)**. Se uma fração dos pixels da tela satisfizer a condição `if` e a outra fração cair no `else`, a GPU é forçada a executar sequencialmente ambos os caminhos de código, desativando temporariamente o paralelismo e degradando o desempenho.

Ao utilizar o `step(0.5, blend)`, o shader calcula um vetor multiplicador binário (`0.0` ou `1.0`) que decide o peso da interpolação dentro do `mix()`. 
* **Vantagem:** Toda a massa de pixels executa exatamente as mesmas operações matemáticas simultaneamente, sem desvios de fluxo no hardware.

Essa técnica de otimização de baixo nível é importante para garantir a viabilidade da simulação híbrida do solo deformável. Ela reduz os milissegundos gastos na renderização de cada frame da cena, liberando o processamento da máquina para a validação em tempo real dos modelos constitutivos de física granular da biblioteca *ExoPhysics*, sendo determinante para manter o **Fator de Tempo Real (FTR)** estável.
