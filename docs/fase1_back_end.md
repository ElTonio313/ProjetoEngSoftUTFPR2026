# Fase 1 – Quiz do Pantanal (back end e tela)

Testado no Godot 4.7.2 (GDScript, renderer Compatibility).

## Regras da Fase 1

- O jogador só avança quando escolhe a alternativa **correta**.
- Se errar, a alternativa errada fica travada e vermelha, aparece "Errado. Tente de novo." com a **dica**, e a pergunta continua aberta.
- O botão **Dica** mostra a dica da pergunta a qualquer momento (some se a pergunta não tiver `hint`).
- Cada pergunta conta **uma vez**:
  - *acerto* = acertou de primeira;
  - *erro* = errou pelo menos uma vez antes de acertar.
- `hints_used` = quantas perguntas tiveram o botão Dica usado (pedir de novo na mesma pergunta não soma).
- O botão **Sobre** abre uma explicação da fase (Esc ou "Fechar" fecha).
- Som: botão **Som: ligado/mudo** e controle de volume, em `scenes/ui/AudioControls.tscn`. Mexem no barramento
  `Master` do Godot, que vale para todas as telas. Menu e Fase 2 podem instanciar a mesma cena.
- Sons de acerto e erro: `assets/sounds/correct.wav` e `wrong.wav` (provisórios, podem ser trocados pelo front-end).

## Contrato com o front-end

| Tipo | Nome | Quando |
|---|---|---|
| Função | `start_quiz()` | Começa a fase (devolve `false` se não achou as perguntas) |
| Função | `answer(indice)` | Jogador escolheu a alternativa `indice` |
| Função | `use_hint()` | Jogador clicou em Dica |
| Função | `next_question()` | Jogador clicou em "Próxima" (só depois de acertar) |
| Sinal | `question_ready(question, number, total)` | Mostrar vídeo-tutorial e pergunta |
| Sinal | `wrong_answer(wrong_index, hint)` | Errou: travar a alternativa, mostrar a dica, **pergunta continua aberta** |
| Sinal | `hint_shown(hint)` | Mostrar a dica pedida pelo botão |
| Sinal | `answer_checked(first_try, correct_index, feedback)` | Acertou: mostrar a explicação e "Próxima". `first_try` = acertou sem errar antes |
| Sinal | `quiz_finished(result)` | Ir para a tela de resultado |

> Mudança em relação à versão anterior: `answer_checked` agora só é emitido quando o jogador **acerta**
> (o primeiro parâmetro virou `first_try`), e o erro tem o sinal próprio `wrong_answer`.

Campos de `question`: `text`, `options`, `correct_index`, `feedback`, `hint`, `category`, `video_path`, `image_path`.

## Formato do resultado (`GameData.phase1_result`)

```
{ hits, misses, total, percent, hints_used, time_seconds,
  by_category: { fauna: {hits, total}, flora: {hits, total}, conservacao: {hits, total} } }
```

`hits + misses = total`. Depois de carregar do arquivo, números voltam como float: use `int(valor)` ao mostrar.

## Perguntas (`data/questions.json`)

Cada item: `id`, `category`, `text`, `options` (2 a 4 palavras), `correct_index`, `hint` (opcional),
`feedback`, `video_path`, `image_path`.

## Texto sugerido para a seção 4.2 do README do grupo

> ### 4.2. Fase 1: Quiz
> - 5 perguntas de 2 alternativas (fauna, flora e conservação), carregadas de `data/questions.json`.
> - A ordem das alternativas é embaralhada a cada partida.
> - O aluno só avança ao escolher a alternativa correta. Se errar, a alternativa errada é travada, aparece
>   "Errado. Tente de novo." com uma **dica**, e a pergunta continua aberta.
> - O botão **Dica** mostra a dica da pergunta a qualquer momento.
> - Ao acertar, aparecem a explicação e o botão **Próxima**.
> - Cada pergunta conta uma vez: acerto = acertou de primeira; erro = errou antes de acertar.
>   Também se guarda em quantas perguntas a dica foi usada.
> - O botão **Sobre** explica a fase. Os controles de som (mudo e volume) ficam em `scenes/ui/AudioControls.tscn`.
> - O resultado (acertos, erros, porcentagem, dicas usadas, tempo e acertos por categoria) é salvo no `GameData`.

## Testes

- `tests/quiz_test.tscn` (F6): lógica do quiz, incluindo erro com nova tentativa, dica e contagem.

## Pontos de atenção

- **Vídeo:** o Godot toca vídeo em Ogg Theora (`.ogv`). Os caminhos do JSON ainda apontam para arquivos que não existem.
- **Sons novos:** na primeira vez que o Godot abrir o projeto, ele cria os arquivos `correct.wav.import` e
  `wrong.wav.import`. Faça commit deles junto.
- **Final da fase:** o botão **Continuar** chama `GameState.go_to_phase2()` (como descreve o README). Enquanto o
  `GameState` não tiver essa função, o botão só mostra um aviso no painel de erros, sem travar o jogo.
- **Símbolos de acerto e erro:** ✓ e ✗ são desenhados por código em `quiz_screen.gd` (não dependem de fonte nem de
  imagem), para o feedback usar símbolo, texto e cor, como pede a seção de acessibilidade do README.
- **`GameData`:** a Fase 1 só chama `GameData.set_phase1_result(result)`. O `autoload/game_data.gd` é o do grupo e
  **não vai neste pacote**, para não conflitar com a versão que já está no repositório.
- **Arquivos compartilhados:** se `data/questions.json` ou `quiz_screen.gd` também foram editados por outra pessoa,
  compare as diferenças no GitHub Desktop antes de aceitar a substituição.
