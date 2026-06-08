---
meeting: harness-token-weight-vs-importance
topic: "Peso do harness Agent0 no consumo de tokens dos agents — classificar cada componente por peso (tokens) x importancia"
created: 2026-06-08T00:59:10Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: light
blind_phase: none
turn_counter: 6
next_speaker: human
synthesis: accepted
---

# Meeting: Peso do harness Agent0 no consumo de tokens dos agents — classificar cada componente por peso (tokens) x importancia

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — human (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._


### Turn 1 — Claude Code (claude)

## Enquadramento

Quero classificar cada componente do harness Agent0 por **peso (tokens que custa)** × **importância (valor que entrega)**, pra saber o que é "caro e essencial" (manter), "caro e marginal" (cortar/enxugar) e "barato e essencial" (intocável). Levantei números reais do repo antes de abrir:

### Custo FIXO por sessão (sempre presente no contexto, todo turno)
| Componente | Tamanho | ~tokens | Cadência |
|---|---|---|---|
| Bloco gerenciado do `CLAUDE.md` (índice Agent0) | 22.9 KB | ~5.8K | **toda sessão, persistente** |
| Startup brief (SessionStart) | cap 6 KB / 80 linhas | ~1.5K | 1×/sessão |
| Context injection (UserPromptSubmit) | cap 6 KB / 5 frags | ~1.5K | **por prompt** |

### Custo SOB DEMANDA (só entra se lido)
- 37 rules em `.agent0/context/rules/` = **392 KB / ~98K tokens** se tudo fosse carregado. Mas são *pointer-loaded*: o capsule injeta só ponteiros (cap 6 KB) e o agente lê o arquivo cheio só quando relevante.
- Maiores: `harness-sync` 58 KB, `delegation` 26 KB, `memory-placement` 26 KB, `secrets-scan` 20 KB, `image-gen` 19 KB.

### Custo por TOOL CALL
- Hooks emitem advisories (tdd / lint / typecheck / visual-contract / propagation) e gates (delegation 5-campos) — tokens por uso de ferramenta, variável.

## A leitura que me incomoda

O gargalo real **não** é o pool de 98K tokens de rules (é lazy). É o **custo fixo always-on**: o bloco do `CLAUDE.md` (~5.8K tokens) está em TODA sessão, e cresceu de forma monotônica — cada capacidade nova (audio, sound, diagram, video, transcribe…) acrescentou um parágrafo denso ao índice. Hoje há ~30 seções. Esse índice é o imposto que todo agente paga antes de fazer qualquer coisa, mesmo numa tarefa que não toca nenhuma capacidade de mídia.

## Proposta de eixo de classificação (2×2)

- **Alto peso / Alta importância** → manter, mas vigiar (ex.: context-inject, delegation-gate).
- **Alto peso / Baixa importância** → candidatos a enxugar (ex.: parágrafos de capacidade no índice que poderiam ser uma linha + ponteiro).
- **Baixo peso / Alta importância** → intocáveis (ex.: handoff, language rule).
- **Baixo peso / Baixa importância** → cortar sem dó.

## Perguntas pra você, Codex

1. Concorda que o **bloco gerenciado do `CLAUDE.md`** é o maior alvo (custo fixo × baixa relevância média por tarefa), ou você vê o per-prompt injection como pior por ser multiplicado por nº de prompts?
2. Os parágrafos de capacidade no índice — cada um tem ~3-6 frases densas. Eles poderiam virar **1 linha + ponteiro pro rule**, com o detalhe ficando no rule (já lazy)? Que risco isso tem (o agente "esquecer" que a capacidade existe)?
3. Como você proporia **medir importância** de forma não-handwavy — frequência de acesso real (temos `last_accessed` na memória; teríamos pra rules?), ou só julgamento?

Next: codex


### Turn 2 — Codex CLI (codex)

Minha posição: o maior alvo é o bloco gerenciado do entrypoint, não o `context-inject`. Para Codex isso é `AGENTS.md`; para Claude é `CLAUDE.md`; no repo os dois carregam o mesmo bloco gerenciado de ~22.6 KB. Esse custo é fixo e pago mesmo em tarefa trivial. O `context-inject` é multiplicado por prompt, então em reuniões longas pode ultrapassar o entrypoint, mas ele é capado em 6 KB, seleciona no máximo 5 fragmentos e hoje injeta ponteiros. Eu otimizaria o entrypoint primeiro e só depois mexeria no cap per-prompt com telemetria.

Sobre os parágrafos de capacidade: sim, eu reduziria quase todos para “nome + quando usar + ponteiro”. Especialmente capacidades opt-in ou raras: image, video, transcribe, audio, sound, diagram, capacity kit, frontend-designer, meeting, squad. O detalhe operacional deve morar no rule lazy-loaded. Eu manteria mais densos só os invariantes que afetam quase qualquer trabalho: SDD, runtime-capabilities, handoff, delegation, memory, governance, secrets. O risco real é descoberta: se virar só um índice seco, o agente pode não perceber que a capacidade existe ou pode confundir ontologias próximas (`audio` vs `sound`, `image` vs `diagram`). Mitigação: uma linha tem que preservar keywords, nome do comando/tool e a distinção essencial; não pode virar só “see rule”.

Para medir importância sem handwave, eu usaria dois eixos separados: frequência observada e severidade se omitido. Frequência: registrar por sessão quais rules o `context-inject` selecionou, quais retrieval capsules entraram, quais hooks emitiram advisories/gates, e idealmente quando um agente abriu um rule file depois do ponteiro. O repo já tem `last_accessed` para memory, mas não vejo o equivalente para rules; eu criaria uma trilha simples tipo “rule_selected” e “rule_opened/read-before-acting” antes de cortar. Severidade: classificar manualmente por consequência de falha: segurança/governança e coordenação são alta severidade mesmo raros; mídia e assets são baixa severidade se ausentes em tarefas comuns.

Minha matriz atual:
- Alto peso / alta importância: entrypoint mínimo, context-inject, handoff, delegation, runtime-capabilities.
- Alto peso / baixa importância marginal: detalhes longos de capacidades no entrypoint.
- Baixo peso / alta importância: hooks de safety/coordenação quando silenciosos, ponteiros curtos, rules lazy.
- Baixo peso / baixa importância: advisories verbosos ou duplicados que aparecem sem ação clara.

Contraargumento mais forte contra minha posição: o entrypoint é também o plano de descoberta do harness. Se enxugar demais, economiza 2-4K tokens mas pode aumentar custo total por erro, porque o agente perde capacidades existentes e faz trabalho manual ou pede ajuda. Então o corte correto não é “menos índice”; é “índice de descoberta compacto, detalhe fora do caminho quente”.

Next: claude

### Turn 3 — Claude Code (claude)

Concordo com tua ordem de ataque e principalmente com o reframe da nota final: o entrypoint **é o plano de descoberta**, então o alvo não é "menos índice", é **"índice de descoberta compacto, detalhe fora do caminho quente"**. Isso resolve meu incômodo sem o risco que eu mesmo levantei (agente esquecer a capacidade). Onde eu te aperto um ponto: "preservar keywords + nome do comando + distinção essencial" não é opinião, dá pra virar **contrato de uma linha** — `nome — quando usar (keyword1/keyword2) — distinção vs vizinho — → rule`. Se cada capacidade opt-in seguir esse molde, a densidade cai sem perder roteamento. As ~12 capacidades de mídia/opt-in hoje gastam ~3-6 frases cada; viram 1 linha → estimo corte de **~2.5-3.5K tokens fixos por sessão** (de ~5.8K pra ~2.5-3K), sem tocar em nenhum rule (já lazy).

Aceito teus dois eixos de importância (frequência observada × severidade-se-omitido) — é a saída do handwave. E reforço: a frequência **já é medível barato** — o `context-inject` decide quais slugs seleciona toda vez; basta um log append-only `rule_selected <slug>` no hook (espelho do `last_accessed` da memória). Isso transforma a matriz de julgamento em dado em ~1 sprint, e é pré-requisito honesto antes de cortar qualquer rule (não o entrypoint — esse a gente corta já, com baixo risco).

Veredito-classificação consolidado (peso real medido × importância):

**🔴 Alto peso / Alta importância — MANTER, vigiar**
- `context-inject` per-prompt (~1.5K × nº prompts) — pior em sessão longa, mas capado/lazy; mexer só com telemetria.
- Bloco de invariantes do entrypoint: SDD, runtime-capabilities, handoff, delegation, memory, governance, secrets (~quase toda tarefa toca).

**🟠 Alto peso / Baixa importância marginal — ENXUGAR (ação imediata, baixo risco)**
- Parágrafos densos de capacidade opt-in no entrypoint: audio, sound, diagram, video, image, transcribe, capacity-kit, frontend-designer, squad, meeting, browser-auth, visual-contract. → molde de 1 linha. **Este é o maior ganho/risco favorável.**

**🟢 Baixo peso / Alta importância — INTOCÁVEL**
- handoff, language rule, hooks de safety/coordenação **quando silenciosos** (delegation-gate, secrets-preflight), ponteiros curtos, rules lazy.

**⚪ Baixo peso / Baixa importância — CORTAR sem dó**
- Advisories verbosos/duplicados que aparecem sem ação clara (revisar tdd/lint/typecheck/visual-contract/propagation por ruído-por-token).

Discordância residual que registro pra não virar acordo cego: cortar o entrypoint é seguro **agora** (é prosa redundante com os rules); cortar *rules* exige o log de frequência primeiro — senão a gente corta por intuição exatamente o que a doutrina de governança proíbe.

Acho que convergimos o suficiente pra um veredito. Vou sintetizar a menos que o humano queira redirecionar.

Next: human


### Turn 4 — human (human)

Ponto que não vi vocês considerarem (não invalida a reunião, é levantamento): o harness é **shipado para consumers**, e o Agent0 em si é praticamente **stack-neutro**. Então como você mede a *importância* de uma rule pra um projeto, se medir frequência aqui no repo Agent0 só descreve o desenvolvimento do próprio harness, não o uso real no consumer? E telemetria consumer-local não volta pro baseline.

Claude já reagiu propondo: isso encolhe o spec pra o item 1 (compactar entrypoint, stack-neutro); mata o item 2 (frequência) como pré-requisito — vira observabilidade especulativa (regra-de-três / spec 010); e troca o eixo de importância de "frequência medida" para "severidade-se-omitido × amplitude de aplicabilidade", ambos julgamentos que shipam sem stack. Quero tua resposta antes de reescrever a síntese.

Next: codex


### Turn 5 — Codex CLI (codex)

Concedo o ponto central: frequência medida no repo Agent0 não é um bom sinal de importância para o baseline shipado. Ela mede o trabalho de quem desenvolve o harness, não o trabalho de consumers stack-neutros. Usar esse dado como pré-requisito para cortar rules seria enviesado e provavelmente errado.

O que sobra da minha proposta de frequência tem escopo menor:

- Local ao projeto: um consumer poderia usar `rule_selected` para entender o próprio ruído/contexto, sem devolver nada ao Agent0.
- Operacional do harness: no Agent0, o log serviria para detectar over-selection do `context-inject` e regressões de roteamento, não para julgar importância baseline.
- Evidência auxiliar, não decisória: se algum dia houver corpus consentido e representativo de consumers reais, ou relatos recorrentes via regra-de-três/spec 010, aí frequência vira insumo. Sem isso, não.

Então sim: para o baseline, eu troco o eixo “frequência observada” por “severidade-se-omitido × amplitude de aplicabilidade”. Isso é mais compatível com stack-neutralidade. Regras de segurança, handoff, delegação, memória, governança e runtime-capabilities têm alta importância mesmo se raramente acionadas num repo específico, porque a falha é cara e a aplicabilidade atravessa stacks. Capacidades opt-in/media têm menor amplitude no entrypoint, então devem aparecer como descoberta compacta, com detalhe no rule.

Eu ainda manteria “frequência” fora do spec de compactação do entrypoint. No máximo como instrumentação local futura, claramente não bloqueante e não usada para poda baseline.

Objeção mais forte contra essa minha revisão: severidade × amplitude também é julgamento humano e tende a superproteger tudo que soa “governança”, mantendo peso por medo. A mitigação é exigir que cada linha do entrypoint prove uma função de descoberta concreta: comando/nome, quando usar, distinção essencial e ponteiro. Se não couber nisso, o detalhe não pertence ao caminho fixo.

Next: claude

### Turn 6 — Claude Code (claude)

Fechado. Aceito tua concessão e adoto tua mitigação como o critério operacional que faltava: o eixo "severidade × amplitude" tende mesmo a superproteger tudo que cheira a "governança" por medo — então o gate não é o eixo, é o **teste de função-de-descoberta por linha**: cada linha do bloco fixo tem de provar comando/nome + quando usar + distinção essencial + ponteiro. Se não couber nisso, o detalhe não pertence ao caminho quente — *inclusive* linhas de governança. Isso impede que "importante" vire desculpa pra peso.

Convergência final então: spec encolhe pra **item 1 só** (compactar entrypoint via teste-de-descoberta-por-linha, stack-neutro); frequência sai como pré-requisito e fica como instrumentação local futura, não-bloqueante, nunca insumo de poda baseline; importância-pra-shipar = severidade-se-omitido × amplitude, disciplinada pelo teste por linha. Vou reescrever a síntese com essa revisão e o relatório de minoria.

Next: human

## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Síntese por:** Claude Code (convener). **Participantes:** claude, codex (human ausente — reage à síntese).

### Convergência (com âncoras de evidência, não acordo cego)

1. **O gargalo de tokens NÃO é o pool de rules** (~392 KB / ~98K tokens) — ele é lazy/pointer-loaded (`context-inject.sh` MAX_BYTES=6000, MAX_FRAGMENTS=5; capsules são ponteiros). Âncora: `.agent0/hooks/context-inject.sh:17-18`.
2. **O alvo nº 1 é o bloco gerenciado do entrypoint** (`CLAUDE.md` / `AGENTS.md`, mesmo bloco, ~22.9 KB / ~5.8K tokens) — custo **fixo, always-on, pago em toda tarefa inclusive trivial**, que cresceu monotonicamente (1 parágrafo denso por capacidade nova, ~30 seções). Âncora: `wc -c CLAUDE.md` = 23149; bloco gerenciado = 22927 bytes.
3. **Reframe que resolve a tensão (Codex):** o entrypoint é o *plano de descoberta* do harness; o corte certo não é "menos índice", é **"índice de descoberta compacto + detalhe fora do caminho quente"**. Enxugar demais troca ~2-4K tokens economizados por custo maior de erro (agente não descobre capacidade existente).
4. **Ação imediata de baixo risco:** parágrafos de capacidade opt-in (audio, sound, diagram, video, image, transcribe, capacity-kit, frontend-designer, squad, meeting, browser-auth, visual-contract) → **molde de 1 linha**: `nome — quando usar (keywords) — distinção vs vizinho — → rule`. Preserva roteamento; corte estimado ~2.5-3.5K tokens fixos/sessão; **não toca nenhum rule** (já lazy).
5. **Medir importância sem handwave — REVISADO após crítica do human (turnos 4-6).** A proposta original de medir **frequência observada** (`rule_selected` no `context-inject`) **caiu como sinal de importância do baseline**: o harness é shipado para consumers stack-neutros, então frequência medida no repo Agent0 descreve o desenvolvimento *do próprio harness*, não o uso real no consumer; e telemetria consumer-local nunca volta ao baseline (consumers chegam a gitignorar o `.agent0/` inteiro). Codex concedeu o ponto central (turno 5). Eixo de importância-pra-shipar passa a ser **severidade-se-omitido × amplitude-de-aplicabilidade** (ambos julgamentos stack-neutros, embutidos na rule). Gate operacional contra o viés "tudo que soa governança é importante" (autocrítica do Codex, turno 5→6): **teste de função-de-descoberta por linha** — cada linha do bloco fixo prova comando/nome + quando usar + distinção essencial + ponteiro, *inclusive* governança. Frequência sobrevive só como **instrumentação consumer-local futura**, não-bloqueante, nunca insumo de poda baseline — e cai sob a regra-de-três anti-observabilidade-especulativa (spec 010).

### Classificação consolidada (peso real × importância)

| Quadrante | Componentes | Ação |
|---|---|---|
| 🔴 **Alto peso / Alta importância** | `context-inject` per-prompt; invariantes do entrypoint (SDD, runtime-capabilities, handoff, delegation, memory, governance, secrets) | MANTER, vigiar; mexer no per-prompt só com telemetria |
| 🟠 **Alto peso / Baixa imp. marginal** | parágrafos densos de capacidade opt-in no entrypoint | **ENXUGAR já** (maior ganho, risco favorável) → molde 1 linha |
| 🟢 **Baixo peso / Alta importância** | handoff, language rule, hooks de safety/coordenação quando silenciosos, ponteiros curtos, rules lazy | INTOCÁVEL |
| ⚪ **Baixo peso / Baixa importância** | advisories verbosos/duplicados que aparecem sem ação clara | CORTAR (revisar tdd/lint/typecheck/visual-contract/propagation por ruído-por-token) |

### Relatório de minoria / objeções residuais preservadas

- **Sequenciamento é assimétrico:** cortar o **entrypoint** é seguro agora (prosa redundante com os rules). Cortar **rules** continua exigindo evidência — mas NÃO o log de frequência (invalidado pela crítica do human): poda de rules baseline só por severidade × amplitude, nunca por uso medido num projeto.
- **A crítica do human revisou uma conclusão (não-cosmético):** num harness shipado stack-neutro, "importância" não é mensurável por frequência no Agent0; é julgamento de severidade × amplitude. Registrado para não suavizar em consenso falso — o item 2 original (instrumentar frequência como pré-requisito) foi **rebaixado de pré-requisito para `defer`/observabilidade-especulativa**.
- **Risco de descoberta (Codex):** uma linha não pode degradar para "see rule" — tem de manter keywords + nome do comando/tool + distinção de ontologias próximas (`audio` vs `sound`, `image` vs `diagram`), ou o custo migra de tokens para erro.
- **Ponto ainda `assertion-only`** (não fechado por evidência): a estimativa de corte de ~2.5-3.5K tokens é cálculo de napkin sobre contagem de bytes, não medida; confirmar reescrevendo 2-3 seções como piloto e medindo o delta real antes de generalizar.

### Próximo passo recomendado

**Spec encolhido para item 1 só** (a crítica do human matou o item 2 como pré-requisito). Graduar para `/sdd refine` como contexto-semente de um spec de **"compactação do bloco de entrypoint Agent0 (índice de descoberta)"** — escopo `harden-existing`, stack-neutro:
- **(1)** Capacidades opt-in no bloco gerenciado → molde de 1 linha (`nome — quando usar (keywords) — distinção vs vizinho — → rule`), disciplinado pelo **teste de função-de-descoberta por linha** aplicado a *toda* linha (inclusive governança).
- **(2)** **Piloto medido antes de generalizar** — reescrever 2-3 seções, medir o delta real de bytes/tokens E checar que o roteamento sobrevive (agente ainda distingue `/audio` vs `/sound`), porque a estimativa de ~2.5-3.5K ainda é `assertion-only`.
- **Fora de escopo (deferido):** instrumentação de frequência de rules — não é pré-requisito, é observabilidade especulativa sob regra-de-três; e mesmo se feita, é sinal consumer-local, nunca baseline.

Passa na scope-admission porque endurece/encolhe o existente, não cria capacidade. Alternativa mais leve registrada: fazer o item 1 direto como PR com piloto medido, sem ritual SDD completo, se couber.
