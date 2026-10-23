# Jogo Educativo: Fauna do Pantanal

## Sinopse

Jogo educativo em 2D, desenvolvido na Godot Engine, que apresenta a fauna do Pantanal brasileiro a pessoas com deficiência intelectual. A proposta é ensinar de forma **simples, acessível e interativa**: instruções curtas, uma tarefa por vez, interações fáceis e feedbacks explícitos, que usam texto e símbolos além da cor.

O jogador passa por duas fases e pode errar quantas vezes precisar, porque só avança ao acertar:

1. **Fase 1: Quiz.** Perguntas curtas sobre fauna, flora e conservação do Pantanal.
2. **Fase 2: Classificação.** O aluno arrasta cada animal até o seu grupo: mamíferos, répteis ou aves.

Projeto acadêmico da disciplina de Engenharia de Software, inspirado no estudo de caso da ASSARTE (Ponta Grossa).

> O nome definitivo do jogo ainda não foi escolhido. "Jogo Educativo" é provisório.

---

## 1. Integrantes e divisão

| Integrante | Responsabilidade |
|---|---|
| **Antony** | Lógica da tela de início, tela de nome, Fase 2 e ligações entre as telas |
| **Gabriel** | Lógica da Fase 1 (quiz) |
| **Juan** | Front-end: aparência, assets, cores e identidade visual |
| **Rena e Matheus** | Documentação |

---

## 2. Requisitos do sistema

| Item | Requisito |
|---|---|
| Sistema operacional | Windows 10 |
| Engine | Godot **4.7.2** (versão Standard, com GDScript, não a .NET) |
| Renderizador | Compatibility (leve, adequado a computadores modestos) |
| Entrada | Mouse (teclado nos botões) |
| Resolução de referência | 1280 × 720, com escala automática da interface |
| Controle de versão | Git e GitHub |

### Como executar

1. Clone o repositório.
2. Abra a Godot 4.7.2 e, no Gerenciador de Projetos, escolha **Importar** e selecione o arquivo `project.godot`.
3. Aguarde a primeira importação terminar. Na primeira abertura a Godot reconstrói o cache de classes.
4. Pressione **F5** para executar o jogo pelo menu principal.

Para rodar uma cena isolada, abra-a no editor e pressione **F6**.

---

## 3. Estrutura do projeto

```
├── autoload/                  Scripts globais, ativos durante todo o jogo
│   ├── game_state.gd          Nome do aluno e navegação entre as cenas
│   └── game_data.gd           Resultados das fases (salvos em arquivo)
├── data/
│   ├── questions.json         Perguntas da Fase 1
│   └── animals.json           Animais da Fase 2 (nome, categoria, dica)
├── scenes/
│   ├── menu/                  Menu principal
│   ├── player_name/           Tela de identificação do aluno
│   ├── quiz/                  Tela da Fase 1
│   ├── phase2/                Tela da Fase 2 (introdução, atividade e conclusão)
│   └── phase1/                Cena provisória da Fase 1 (sem uso, a remover)
├── scripts/
│   ├── quiz/                  Lógica da Fase 1 (QuizManager, Question)
│   └── classification/        Lógica da Fase 2 (ClassificationManager, Animal)
└── tests/                     Cenas de teste automático da lógica das duas fases
```

### Fluxo do jogo

```
Menu principal → Identificação do aluno → Fase 1 (quiz) → Fase 2 (classificação)
```

### Como as peças se conectam

- **Autoloads.** O `GameState` guarda o nome do aluno e sabe o caminho de cada cena, e cada tela só pede a navegação (por exemplo, `GameState.go_to_phase2()`). O `GameData` guarda os resultados das fases. Como eles não são destruídos na troca de cena, os dados chegam a qualquer tela.
- **Lógica separada da interface.** Nas duas fases, a lógica (`QuizManager`, `ClassificationManager`) não conhece botões nem telas. A interface chama as funções públicas e reage a **sinais** (`answer_checked`, `exercise_ready`, `phase_finished`). Assim, a aparência pode mudar sem mexer nas regras, e as regras podem ser testadas sem abrir a tela.
- **Dados fora do código.** Perguntas e animais ficam em arquivos JSON, e trocá-los não exige alterar scripts.

---

## 4. Validações e regras principais

### 4.1. Identificação do aluno

| Regra | Comportamento |
|---|---|
| Nome vazio | Mensagem curta pedindo o nome. Não avança |
| Nome só com espaços | Tratado como vazio |
| Mais de **20** caracteres | Mensagem "Use no máximo 20 letras." Não avança (limite preliminar) |
| Espaços nas pontas | Removidos antes de gravar |
| Nome válido | Gravado no `GameState` e usado nas telas seguintes |

### 4.2. Fase 1: Quiz

- 5 perguntas de 2 alternativas (fauna, flora e conservação), carregadas de `data/questions.json`.
- A ordem das alternativas é embaralhada a cada partida.
- Depois de responder, as alternativas são travadas e aparecem o acerto ou erro (texto, cor e destaque nos botões) e uma explicação.
- Cada pergunta só pode ser respondida uma vez.
- O resultado (acertos, erros, porcentagem, tempo e acertos por categoria) é salvo no `GameData`.
- Ao final, o botão **Continuar** leva à Fase 2.

### 4.3. Fase 2: Classificação

**Estrutura**
- Introdução educativa em texto, com botão **Continuar**.
- 6 animais (2 mamíferos, 2 répteis e 2 aves), em **ordem fixa**, um por vez.
- Barra de progresso e texto "X de 6 animais".

**Interação**
- O aluno arrasta o animal até uma das três áreas. Soltar fora de qualquer área não faz nada, e um clique sem arrastar é ignorado.
- O avanço para o próximo animal é feito pelo botão **Próximo animal** (no último, **Concluir**).

**Feedback**
- **Acerto:** mensagem de confirmação com símbolo, texto e cor. O animal deixa de poder ser arrastado.
- **Erro:** mensagem com símbolo e texto e uma **dica** educativa. O aluno tenta de novo quantas vezes precisar.

**Contagem e tempo**
- **Erros:** toda tentativa incorreta é contada uma vez, mesmo que o aluno acerte depois. Guarda-se o total e o número por animal.
- **Progresso:** só avança no acerto, e cada animal conta uma única vez, mesmo com várias tentativas ou com soltas repetidas.
- **Tempo de cada exercício:** começa quando o animal aparece e termina **no instante do acerto**. Os erros não reiniciam o relógio. O tempo de leitura da introdução e o intervalo até clicar em "Próximo animal" não entram na conta.
- O cronômetro **não é mostrado** ao aluno, para não gerar pressão.

**Dados dos animais**
- `data/animals.json` é validado ao carregar: id, nome, categoria e dica são obrigatórios, e a categoria deve ser `mamifero`, `reptil` ou `ave`. Um item inválido é ignorado e o erro é registrado.

**Conclusão**
- Ao classificar os 6 animais, aparece uma tela de parabéns, e o resultado (total de erros e, por animal, tempo e erros) é salvo no `GameData`.

### 4.4. Acessibilidade

- O feedback não depende só de cor: usa também texto e símbolo.
- Texto escuro sobre fundo claro, com fonte grande (28 px ou mais).
- Botões altos (80 px) e áreas de classificação largas.
- Uma tarefa por vez, sem limite de tempo visível e sem elementos distrativos.
- Botões principais com foco de teclado (Enter ou Espaço).

### 4.5. Testes automáticos

| Cena | Verifica |
|---|---|
| `tests/quiz_test.tscn` | Carregamento das perguntas, contagem de acertos e erros, resposta repetida ignorada e gravação do resultado |
| `tests/classification_test.tscn` | Composição dos 6 animais, ordem fixa, validação, contagem de erros, progresso uma vez por animal, medição de tempo e reinício |

Para executar, abra a cena, pressione **F6** e leia a aba **Saída**. O resultado esperado é `TUDO CERTO`.

### 4.6. Ainda em aberto

- Tela final de feedback e relatórios (quantidade, conteúdo e momento ainda em discussão).
- Tempo total da atividade (início da Fase 1 até o fim da Fase 2).
- Funcionamento dos botões **Configurações** (som), **Créditos** e **Sair**. Hoje só o **Jogar** está ativo.
- Lista definitiva de animais, textos e dicas (os atuais são provisórios e precisam de revisão).
- Imagens, vídeos e sons, que dependem do front-end.
- Papel do `GameData` em relação ao `GameState` e a gravação de resultados em disco, incluindo quando limpá-los entre alunos.
