---
meeting: v2-meeting-llm-orchestrator-mode
topic: "v2 do /meeting: vale a pena o modo LLM-orquestrador (um LLM dirige N turnos), e se sim qual o cap de turnos + onde fica o checkpoint humano obrigatorio?"
created: 2026-06-02T16:05:54Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
turn_counter: 3
next_speaker: codex
synthesis: accepted
---

# Meeting: v2 do /meeting: vale a pena o modo LLM-orquestrador (um LLM dirige N turnos), e se sim qual o cap de turnos + onde fica o checkpoint humano obrigatorio?

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the round-robin order of model participants (human excluded), `next_speaker` is whose turn is legal by default, `turn_counter` counts written turns, `synthesis` tracks the close-out. A fresh runtime reads only the front-matter to learn whose turn is legal — the body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — human (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used._


### Turn 1 — Claude Code (claude)

Framing. Hoje o /meeting v1 é humano-orquestrado: o humano dispara cada turno. A pergunta do v2 é se vale um modo onde UM LLM (orquestrador) escolhe o próximo falante e dirige N turnos sozinho — e, se sim, qual o cap e onde entra o checkpoint humano obrigatório.

Minha posição de abertura (para o Codex atacar): vale, mas mínimo e fortemente cercado. O valor real é deixar Claude e Codex trocarem alguns turnos enquanto o humano está ausente, e ele reage à síntese. Mas a tensão é direta com o instinto anti-runaway do Agent0 e com custo (cada turno de peer é um subprocesso pago/lento). Proposta concreta: cap default ~6 turnos de modelo, teto duro 12; ao bater o cap NÃO é corte cego — dispara uma decisão obrigatória "continue / synthesize / abandon" (ideia que você mesmo levantou no smoke), com no máx. 1 grace turn para fechar uma questão nomeada; e um teto de custo por run (--confirm-cost-usd) antes de começar.

Duas perguntas a resolver:
1. A autonomia compensa a complexidade vs. só alternar manualmente? Ou aplicamos o rule-of-three (só construir depois de 3 reuniões reais provarem que a alternância manual é o gargalo)?
2. Mecanismo do cap: hard stop vs. decision-gate + grace turn — e o checkpoint humano fica só no cap, ou também a cada K turnos?

Onde quero pushback: estou menos confiante em (1) — talvez o modo nem deva existir no v2.


### Turn 2 — Codex CLI (codex)

Eu não colocaria o modo LLM-orquestrador como default do v2; eu colocaria atrás de flag experimental e aceitaria o rule-of-three como critério para promovê-lo, não para sequer prototipá-lo. A razão é que o valor é plausível, mas o risco real não é só custo: é o meeting virar um debate autoalimentado sem nova informação humana, o que degrada exatamente o ponto do formato. Eu usaria um bound simples como AutoGen/AG2 fazem com `max_round`: default 4 turnos de modelo, teto duro 8, sem graça automática. No cap, checkpoint humano obrigatório com três ações: sintetizar, continuar com novo cap explícito, ou abandonar. Além disso, eu colocaria um checkpoint humano também quando o orquestrador quiser mudar o objetivo da reunião, adicionar participantes, ou iniciar pesquisa web/paga; esses são saltos de escopo, não meros turnos. Então: shipar sim, mas como “autopilot bounded”, não como novo modo principal; o sucesso do v2 é provar que ele economiza atenção humana sem esconder decisões humanas.

### Turn 3 — Claude Code (claude)

Concordo com a maior parte e mudo de posição em dois pontos. Aceito teu argumento de que o risco dominante não é custo, é o meeting virar debate autoalimentado sem informação humana nova — isso, sim, mata o propósito do formato, e é um argumento melhor que o meu enquadramento "custo/runaway". Por isso retiro o grace turn automático: você está certo que ele é uma continuação disfarçada que escapa do checkpoint. Fico com o teu bound estilo `max_round`: default 4 turnos de modelo, teto duro 8, sem graça.

O ponto mais valioso que você trouxe e que eu não tinha é o **checkpoint por salto-de-escopo**, não só por cap: mudar o objetivo da reunião, adicionar participante, ou iniciar pesquisa web/paga exigem aprovação humana independentemente da contagem de turnos. Aceito e proponho tornar isso a regra central do modo, não um adendo — o cap vira só um dos gatilhos de checkpoint, sendo o outro o salto-de-escopo.

Onde ainda divirjo levemente: "rule-of-three para promover, não para prototipar" pode ser rígido demais — eu permitiria um protótipo atrás da flag experimental já no v2 (custo de não-construir = nunca medir se economiza atenção), mas com a promoção a default exigindo as 3 reuniões reais. Ou seja: prototipar cedo, promover tarde. Convergência geral: "autopilot bounded" atrás de flag, default 4/teto 8, checkpoint humano no cap E em qualquer salto-de-escopo, três ações no checkpoint (sintetizar/continuar-com-novo-cap/abandonar). O único item aberto é se o protótipo entra no v2 ou só depois do rule-of-three.

## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

**Synthesizing runtime:** Claude Code.

**Convergence (Claude + Codex agree):**
- The LLM-orchestrator mode ships as **"bounded autopilot" behind an experimental flag** — never the default meeting mode.
- **Bound like AutoGen/AG2 `max_round`:** default **4** model turns, **hard ceiling 8**, with **no automatic grace turn** (a grace turn is a disguised continuation that escapes the checkpoint).
- **Human checkpoint has two triggers, not one:** (a) hitting the cap, and (b) any **scope-jump** — changing the meeting's objective, adding a participant, or starting web/paid research. Scope-jumps require human approval regardless of turn count; this is the *central* rule of the mode, not an add-on.
- **At a checkpoint, three actions:** synthesize / continue-with-a-new-explicit-cap / abandon.
- **Success criterion:** the mode must *save human attention without hiding human decisions*. The dominant risk it guards against is not cost but the meeting degenerating into a self-feeding model debate with no new human information.

**Recorded disagreement (one, unresolved):**
- **Prototype timing.** Claude: *prototype early* — build it behind the experimental flag already in v2 (cost of not-building = never measuring whether it saves attention), and reserve the rule-of-three only for *promoting* it to default. Codex: apply the **rule-of-three even to prototyping** — don't build until 3 real human-orchestrated meetings show manual alternation is the actual bottleneck. Both agree the rule-of-three governs *promotion to default*; they differ on whether it also governs the *initial prototype*.

**Recommended next step:** *graduate to a spec candidate* — the design is concrete enough to seed a `/sdd refine` for a future "meeting bounded-autopilot mode" spec, whose single load-bearing open question is exactly the prototype-timing disagreement above. The build itself stays deferred; only the spec is drafted now.

**Graduated:** seeded `docs/specs/138-meeting-bounded-autopilot/` (this meeting is its design source).
