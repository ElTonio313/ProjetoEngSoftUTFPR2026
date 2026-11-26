# Aventuras no Pantanal

## Sinopse

Jogo educativo sério em 2D, desenvolvido na Godot Engine, que apresenta a fauna, a flora e a conservação do Pantanal brasileiro (ODS 15 – Vida na Terra) a jovens e adultos com deficiência intelectual. A proposta segue os critérios de acessibilidade e jogos sérios do estudo de caso da **ASSARTE (Associação Artesanal do Excepcional de Ponta Grossa)**.

O jogador passa por duas fases e pode errar quantas vezes precisar, porque só avança ao acertar:

1. **Fase 1: Quiz.** Introdução ilustrada sobre fauna, flora e conservação do Pantanal seguida de 5 perguntas com apoio de dicas, narração em voz, explicações e premiação com medalha, estrelas e figurinhas desbloqueadas.
2. **Fase 2: Classificação.** O aluno classifica 6 animais do Pantanal em seu grupo biológico (**Mamíferos**, **Répteis** ou **Aves**), podendo arrastar o cartão, clicar diretamente ou usar o teclado.

Ao final, o sistema disponibiliza **duas visões de relatório**:
- **Visão do Aluno:** Tela acolhedora e gamificada com estrelas, medalhas desbloqueadas (*Explorador do Pantanal*, *Amigo da Fauna* e *Selo Guardião ODS 15*), miniaturas das espécies e leitura em voz do resumo.
- **Visão do Professor (Histórico + Exportação em PDF):** Relatório pedagógico detalhado com todas as partidas salvas em disco (nome, data/hora, tempo total, estrelas, acertos de primeira, erros, dicas usadas, tempo por animal e **avaliação de coordenação motora fina nos periféricos: arraste vs. clique vs. teclado**), com opção de salvar em **PDF** no local escolhido pelo professor.

---

## 1. Integrantes e divisão

| Integrante | Responsabilidade |
|---|---|
| **Antony Rinaldi Sikorski** | Fluxo entre telas, tela de nome, Fase 2, narrações gravadas (`Narrator` / `.ogg`) e gravação de relatório `.txt` |
| **Gabriel Luiz Lidani** | Lógica da Fase 1 (quiz), introdução e controles de áudio |
| **Juan Estevan Brandão Eleuterio** | Front-end: identidade visual, ilustrações, acessibilidade, Guia Visual, gamificação e relatórios (incluindo exportação em PDF) |
| **Renan Henrique dos Santos Bosca e Matheus de Lima Santos** | Levantamento de requisitos, escopo e documentação |

---

## 2. Requisitos do sistema

| Item | Requisito |
|---|---|
| Sistema operacional | Windows 10 / 11 |
| Engine | Godot **4.7.2** (versão Standard, com GDScript, não a .NET) |
| Renderizador | Compatibility (leve, adequado a computadores modestos) |
| Entrada | Mouse (com Teclado Virtual na tela) e/ou Teclado |
| Resolução de referência | 1280 × 720, com escala automática da interface |
| Controle de versão | Git e GitHub |

### Como executar

1. Clone o repositório.
2. Abra a Godot 4.7.2 e, no Gerenciador de Projetos, escolha **Importar** e selecione o arquivo `project.godot`.
3. Aguarde a primeira importação terminar.
4. Pressione **F5** para executar o jogo pelo menu principal (ou **F6** para testar uma cena isolada).

---

## 3. Estrutura do projeto

```
├── assets/
│   ├── audio/                 Narrações em voz neural (.ogg) para todas as telas, dicas e relatórios
│   ├── images/                Ilustrações 2D do Pantanal, animais, plantas, Guia Visual e fundo
│   ├── sounds/                Efeitos sonoros acessíveis de acerto e erro
│   └── theme/                 Tema global (pantanal_theme.tres com fonte Arial)
├── autoload/                  Scripts globais, ativos durante todo o jogo
│   ├── game_state.gd          Nome do aluno, Caixa Alta, narração, gamificação, relógio e navegação
│   └── game_data.gd           Resultados das fases e histórico do professor (salvos em JSON)
├── data/
│   ├── intro.json             Páginas educativas da introdução
│   ├── questions.json         Perguntas da Fase 1
│   └── animals.json           Animais da Fase 2 (nome, categoria, dica e imagem)
├── docs/
│   └── fase1_back_end.md      Documentação técnica do contrato da Fase 1
├── scenes/
│   ├── menu/                  Menu principal (Jogar, Área do Professor, Configurações, Créditos, Sair)
│   ├── player_name/           Identificação do aluno com Teclado Virtual integrado
│   ├── intro/                 Introdução educativa ilustrada da Fase 1
│   ├── quiz/                  Tela da Fase 1 (Quiz com Guia Visual e premiação por estrelas)
│   ├── phase2/                Tela da Fase 2 (Introdução dos grupos e Classificação)
│   ├── final_reports/         Tela com os 2 Relatórios (Visão do Aluno e Visão do Professor)
│   └── ui/                    Controles reutilizáveis de som (AudioControls)
├── scripts/
│   ├── audio/                 Reprodutor sequencial de narração com prioridades (Narrator)
│   ├── quiz/                  Lógica e caminhos de áudio da Fase 1 (QuizManager, Question, QuizAudio)
│   ├── classification/        Lógica da Fase 2 (ClassificationManager, Animal)
│   ├── report/                Gravação automática de relatório individual em .txt (ReportWriter)
│   └── reports/               Exportador nativo do Relatório do Professor em PDF (PdfExporter)
└── tests/                     Cenas e scripts de teste automático (Quiz, Fase 2, GameState e Narrator)
```

### Fluxo do jogo

```
Menu principal → Identificação do aluno (Teclado Virtual) → Introdução → Fase 1 (Quiz) → Fase 2 (Classificação) → Relatórios (Aluno e Professor)
```

---

## 4. Validações e regras principais

### 4.1. Identificação do aluno
- Suporte a digitação pelo **Teclado Virtual na tela** (clique com o mouse) ou pelo teclado físico.
- Valida nome vazio, apenas espaços e limite máximo de 20 caracteres, exibindo aviso claro com símbolo (`⚠`).

### 4.2. Fase 1: Quiz
- 5 perguntas de 2 alternativas (fauna, flora e conservação), carregadas de `data/questions.json`, acompanhadas de ilustração educativa.
- A ordem das alternativas é embaralhada a cada partida.
- O aluno só avança ao escolher a alternativa correta. Se errar, a alternativa errada é travada com símbolo `✗`, aparece `"ERRADO. TENTE DE NOVO."` com uma **dica**, e a pergunta continua aberta.
- O botão **Dica** mostra a dica da pergunta a qualquer momento.
- Ao acertar, aparecem o símbolo `✓`, a explicação e o botão **Próxima**.
- Cada pergunta conta uma vez: acerto = acertou de primeira; erro = errou antes de acertar. Também se guarda em quantas perguntas a dica foi usada.
- O botão **Sobre** explica a fase. Os controles de som (mudo e volume) ficam em `scenes/ui/AudioControls.tscn`.

### 4.3. Fase 2: Classificação
- Painel explicativo inicial apresentando os 3 grupos (**Mamíferos**, **Répteis** e **Aves**), que também pode ser reaberto a qualquer momento pelo botão **Ver Grupos**.
- 6 animais (2 mamíferos, 2 répteis e 2 aves), em ordem fixa, um por vez, com ilustração e nome.
- **Acessibilidade motora:** O aluno pode tanto **arrastar o cartão do animal** até o grupo quanto **clicar diretamente** (ou usar `Tab` + `Enter`) sobre o grupo desejado.
- Botão **Dica** disponível a qualquer momento para lembrar as características do animal atual.
- Medição individual de tempo e contagem de tentativas incorretas por animal.

### 4.4. Critérios de Acessibilidade e Jogos Sérios Aplicados
- **Narração em voz natural (`.ogg`) e Guia Visual (Guarda-Parque do Pantanal):** Leitura acolhedora em português em todas as telas, botão **Ouvir**, leitura ao passar o mouse sobre opções/botões e opção de ligar/desligar em Configurações.
- **Fonte Arial e Letras em CAIXA ALTA** por padrão em todas as telas (com opção de alternância em Configurações).
- **Teclado Virtual na tela** para evitar dependência do teclado físico ou combinação de teclas.
- **Dupla modalidade motora na Fase 2** (arrastar, clicar ou teclado) para atender alunos com dificuldade de coordenação motora fina, registrando o periférico utilizado para acompanhamento pedagógico do professor.
- **Feedback multimodal e gamificação:** Símbolos (`✓`, `✗`, `⚠`), texto, som suave, estrelas douradas, medalhas e figurinhas desbloqueadas.
- **Cores confortáveis e sem excesso de luminosidade:** Fundo fosco em tom areia/creme com paisagem suavizada, cartões claros de alto contraste e linguagem adequada a jovens e adultos (> 16 anos), sem infantilização.
- **Animações suaves** nos botões e cartões para guiar a atenção sem poluição visual.

### 4.5. Testes automáticos

| Cena | Verifica |
|---|---|
| `tests/quiz_test.tscn` | Carregamento das perguntas, contagem de acertos/erros/dicas, tentativa após erro e gravação no `GameData` |
| `tests/classification_test.tscn` | Composição dos 6 animais, ordem fixa, validação, contagem de erros, progresso e medição de tempo |
| `tests/game_state_test.tscn` | Medição do tempo total da atividade e reinício de sessão no `GameState` |
| `tests/narrator_test.tscn` | Fila, prioridade e interrupção limpa de áudios no `Narrator` |

Para executar, abra a cena na Godot, pressione **F6** e leia a aba **Saída** (`TUDO CERTO`).
