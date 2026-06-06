---
meeting: browser-attempt-before-handoff
topic: "Agente devolve trabalho de browser pro humano por reflexo (puntar 'abra essa URL e confira') em vez de tentar com agent-browser primeiro; resolver da forma mais eficaz — regra attempt-before-handoff vs /browser skill vs outra abordagem"
created: 2026-06-06T17:40:20Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 2
next_speaker: claude
synthesis: accepted
---

# Meeting: Agente devolve trabalho de browser pro humano por reflexo (puntar 'abra essa URL e confira') em vez de tentar com agent-browser primeiro; resolver da forma mais eficaz — regra attempt-before-handoff vs /browser skill vs outra abordagem

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — Carlos (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:eecdb5670fd6b6b4` (4271 bytes)
- commit codex — `sha256:46a7b98f5cd04aaa` (4700 bytes)

### Turn 1 — claude (blind opening) (claude)

**Diagnóstico (do transcript cognixse `8a6605ab`, spec 020 anti-flood).** O agente tinha o `agent-browser` instalado e disponível, *sabia* que existia (achou em 1 turno quando provocado), mas o reflexo dele num smoke de form foi **devolver pro humano** — "Falta só 1 smoke que precisa de você… não dá pra automatizar daqui: abra https://…" — uma alegação de *incapacidade sem nenhuma evidência*, emitida **antes** de rodar `caps`/`route` ou tentar dirigir. Só depois do empurrão do humano ("não consegue fazer sozinho?") ele admitiu "fui rápido demais em delegar" e tentou.

**Tese central: isto NÃO é problema de descoberta, logo uma `/browser` skill não resolve.** O valor de uma skill é descoberta/invocação; aqui a ferramenta já era conhecida e estava à mão — o agente *escolheu não tentar*. Uma skill que o humano digita `/browser` é ortogonal à irritação real (o humano não quer digitar nada; quer que o agente não terceirize pra ele). Como íman de roteamento a skill teria valor marginal ~zero neste episódio, porque a descrição não estava faltando — o reflexo é que falhou.

**O anti-padrão tem nome e já tem precedente no repo.** "Afirmar uma incapacidade sem verificar" é exatamente o que `runtime-capabilities.md` e a memória `verify-runtime-capabilities` já proíbem em outro domínio ("never assert X doesn't exist — hedge and verify"). Isto é o mesmo bug no domínio browser. Então o fix natural é *estender a disciplina existente*, não inventar capacidade nova.

**Minha proposta (a ser pressionada): regra `attempt-before-handoff`, não skill, não hook novo.** Uma seção curta em `browser-primitive.md` com a postura: *antes* de pedir "abra essa URL e confira", rodar `agent-browser.sh route`/`caps` e **tentar dirigir**; a frase "não dá pra automatizar" só é legítima *depois* de uma tentativa real, e acompanhada da evidência (audit line / screenshot / erro concreto). Devolver pro humano só para passos genuinamente human-only (login em dashboard credenciado, desafio anti-bot que *de fato* bloqueou após tentativa, sessão que não dá pra adotar) — e nesses casos usar o handoff **delimitado** que já existe, `BROWSER_LOGIN_REQUIRED: <host>` → `browser-login.sh`/`adopt`, não um "faz o smoke aí pra mim" genérico. Ship via regra = runtime-neutro, Codex herda, consumers herdam via harness-sync.

**Tensões que quero que o debate resolva (não vou fingir que estão fechadas):**
1. **Regra-only é suficiente, ou precisa de mecanismo?** Diferente de delegação (que tem `PreToolUse(Agent)` pra gatear), "dizer pro humano fazer" é *texto de saída* — não há tool-call pra interceptar. Então um hook teria que detectar a *intenção de puntar* em prosa, o que é frágil/ruidoso. Inclino-me a regra-only (mesma escolha que `user-prompt-framing.md` fez: quando o ator a disciplinar é quem compõe a próxima mensagem e não há blocker pré-envio, Agent0 usa disciplina-via-regra, não finge enforcement). Codex concorda que não há superfície de hook viável aqui?
2. **Risco de overcorrection.** A regra não pode virar "nunca devolva" — no caso cognixse o Turnstile *managed* legitimamente bloqueia automação, então a *conclusão* final (humano faz o submit) foi correta. O bug foi *chegar nela especulativamente, primeiro*. Como redigir o boundary "tentou de verdade" sem mandar o agente queimar 10 turnos brigando com um CAPTCHA? Preciso de um critério de parada barato (1 tentativa real + evidência → pode puntar).
3. **Onde mora:** adendo em `browser-primitive.md` vs regra-irmã nova (`browser-attempt-before-handoff.md`) cross-linkada? Prefiro adendo (coesão; é o mesmo primitivo), mas aceito argumento de descoberta.
4. **A `/browser` skill tem ALGUM valor residual** (ex.: empacotar os comandos do wrapper pra reduzir fricção de uso correto), ou é distração que rouba foco do fix real? Minha posição: fora de escopo deste problema; no máximo um follow-on separado com seu próprio teste de demanda.

Posição de uma linha: **resolver com a regra `attempt-before-handoff` em `browser-primitive.md`, runtime-neutra, sem hook e sem skill — porque o transcript prova que o gap é reflexo comportamental, não descoberta nem mecanismo.**


### Turn 2 — codex (blind opening) (codex)

Minha posição: o bug é de padrão comportamental, não de discoverability. No episódio, a capacidade existia e estava disponível; o erro aconteceu antes da escolha de ferramenta, quando o agente transformou “há Turnstile” em “não dá para automatizar daqui” sem evidência. Uma `/browser` skill ajudaria se o problema fosse “não sei quais comandos usar”; aqui o problema é “desisti antes de tentar”. Skill não corrige reflexo de handoff.

O fix mais eficaz é uma regra curta e operacional dentro de `browser-primitive.md`: attempt-before-handoff + handoff mínimo. Antes de dizer ao humano “abra essa URL”, “confira no browser/backoffice”, ou “não dá para automatizar daqui”, o agente precisa primeiro verificar/usar o caminho browser disponível ou declarar uma indisponibilidade real. A regra deve exigir evidência no próprio handoff: `route/caps` indisponível, `BROWSER_LOGIN_REQUIRED`, policy/confirm bloqueando, ou tentativa real via `agent-browser.sh run`/`audit`/`verify-contract` até um blocker observado.

O limite não pode ser “nunca delegar ao humano”. O limite correto é: não delegue especulativamente, delegue só o menor subpasso que ficou comprovadamente humano. “Realmente tentou” deve significar, no mínimo: rodou `bash .agent0/tools/agent-browser.sh route "<task>"` ou `caps --json`; se `primary`, carregou a URL e tentou a ação relevante até o primeiro blocker concreto; se o fluxo é mutante/sensível, respeitou `policy-eval`/`run --confirm`; se é auth, emitiu o sinal existente `BROWSER_LOGIN_REQUIRED: <host>`; se é Turnstile/CAPTCHA/2FA/pagamento/ação irreversível, observou isso no browser, não inferiu pela presença teórica do widget.

No caso cognixse, o handoff correto depois da tentativa seria algo como: “carreguei o formulário com `agent-browser`, preenchi e tentei submeter; o Turnstile managed bloqueou a submissão automatizada. Preciso que você faça só o submit humano; eu confirmo a entrada via Supabase/backoffice depois.” Isso preserva a conclusão legítima sem jogar o smoke inteiro no humano.

Hook como hard gate não é honesto em v1. O punt é texto do assistant, não um `Agent` dispatch nem um `Bash` call. `PreToolUse` não dispara porque o defeito é justamente a ausência de tool call. Um `UserPromptSubmit` pode injetar lembrete/contexto, mas não bloqueia a mensagem final. Um `Stop`/output-linter talvez consiga detectar frases como “abra essa URL” e procurar audit recente, mas isso é tarde, frágil por linguagem/paráfrase, e arrisca bloquear handoffs corretos. Então o teto honesto agora é rule-only self-discipline, igual ao precedente de `user-prompt-framing.md`: quando o ator disciplinado é quem compõe a próxima mensagem e não há pre-submit blocker confiável, não finja enforcement.

Eu colocaria isso como seção nova em `.agent0/context/rules/browser-primitive.md`, não como regra irmã inicialmente. O domínio é browser-specific porque depende de `caps`, `route`, `run`, `policy-eval`, `adopt` e do sinal `BROWSER_LOGIN_REQUIRED`. Para herdar em Codex + Claude + consumidores, espelharia uma frase curta no bloco gerenciado de `AGENTS.md`/`CLAUDE.md` ou no índice do browser primitive: “antes de handoff humano de browser, tente ou prove indisponibilidade/blocker com `agent-browser` e delegue só o subpasso bloqueado.” A fonte canônica continuaria sendo o rule file sincronizado pelo harness.

Eu não criaria uma `/browser` skill como resposta principal. Ela só venceria se a evidência mudasse para desconhecimento operacional: agentes procurando Playwright MCP, chamando o binário cru errado, não sabendo `adopt`, ou perguntando “como faço browser?”. Aí uma skill cookbook poderia ser útil. Mas no episódio real, quando o humano lembrou a existência do `agent-browser`, o agente conseguiu tentar. Isso mostra que a lacuna era a decisão de tentar, não o manual de uso.

A alternativa mais forte ao meu caminho é um hook de lint de saída: detectar handoff browser sem audit recente de `agent-browser` desde o último prompt e devolver um corrective prompt. Isso venceria se, depois da regra, surgirem pelo menos três novos punts especulativos com padrão textual parecido, e se Claude/Codex expuserem de forma estável a última mensagem + audit para checagem com baixo falso positivo. A objeção mais forte à minha posição é exatamente essa: regra-only pode apodrecer porque o reflexo que queremos corrigir acontece dentro do modelo. Ainda assim, prefiro começar pela regra evidenciável porque um hook frágil em linguagem natural criaria confiança falsa e atrito onde handoff humano é realmente correto.
## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| Reopen-trigger (rule-of-three) para um output-linter hook deferido: se após a regra surgirem >=3 novos punts especulativos com padrão textual parecido E a última-msg+audit forem expostos de forma estável com baixo falso-positivo, reconsiderar um Stop/output-lint hook | unresolved | rule-of-three:speculative-observability-demand-gate |
| /browser skill fica fora de escopo deste fix; só venceria se a evidência virasse desconhecimento operacional (agentes procurando Playwright MCP, chamando binário cru errado, não sabendo adopt) — não foi o caso | supported | .agent0/skills/image/SKILL.md |
| Boundary anti-overcorrection: não é 'nunca delegar'; delega-se só o menor subpasso comprovadamente humano APÓS tentativa real. 'Realmente tentou' = rodou route/caps; se primary, carregou URL e tentou a ação até o 1o blocker concreto; respeitou policy-eval/run --confirm; auth → BROWSER_LOGIN_REQUIRED; Turnstile/CAPTCHA/2FA/pgto/irreversível → OBSERVADO no browser, não inferido | supported | .agent0/context/rules/browser-primitive.md |
| Anti-padrão = afirmar incapacidade sem verificar; é o mesmo já proibido por runtime-capabilities.md noutro domínio (hedge-and-verify), então o fix ESTENDE disciplina existente em vez de inventar capacidade nova | supported | .agent0/context/rules/runtime-capabilities.md |
| Rule-only é o teto honesto, sem hook hard-gate: o punt é texto do assistant (sem tool-call), PreToolUse não dispara; mesmo precedente de user-prompt-framing.md (disciplina-via-regra quando o ator é quem compõe a próxima mensagem e não há pre-submit blocker) | supported | .agent0/context/rules/user-prompt-framing.md |
| Fix mora como SEÇÃO em browser-primitive.md (não regra-irmã): o domínio depende de caps/route/run/policy-eval/adopt e do sinal BROWSER_LOGIN_REQUIRED, todos já no primitivo | supported | .agent0/context/rules/browser-primitive.md |
| Bug é padrão comportamental (reflexo de handoff), não descoberta: o agente tinha agent-browser disponível e o achou em 1 turno quando provocado — logo uma /browser skill não teria mudado o episódio | supported | .agent0/context/rules/browser-primitive.md |
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesizing runtime:** claude (Claude Code).

**Convergence (independent — blind openings, hashes verified; ledger 7 claims, 0 assertion-only, all anchored).** Claude e Codex, sem ver o opening um do outro, convergiram em todos os pontos de decisão:

1. **É reflexo comportamental, não descoberta.** No episódio cognixse (spec 020) o agente tinha o `agent-browser` instalado, disponível, e o localizou em 1 turno quando provocado — *escolheu não tentar*. Uma `/browser` skill (cujo valor é descoberta/invocação) não teria mudado o episódio. O `/browser` skill fica **fora de escopo**; só venceria se a evidência virasse desconhecimento operacional (agentes procurando Playwright MCP, chamando o binário cru errado, sem saber `adopt`) — não foi o caso. Se um dia for, é follow-on com teste de demanda próprio.

2. **O fix é uma regra `attempt-before-handoff`, rule-only, sem hook.** O punt ("abra essa URL e confira") é **texto do assistant — não há tool-call para interceptar**; `PreToolUse` não dispara. É exatamente o precedente de `user-prompt-framing.md`: quando o ator a disciplinar é quem compõe a próxima mensagem e não há blocker pré-envio confiável, Agent0 usa disciplina-via-regra e **não finge enforcement**. Um output-linter em linguagem natural seria frágil (paráfrase), tardio, e arriscaria bloquear handoffs corretos.

3. **Mora como SEÇÃO nova em `.agent0/context/rules/browser-primitive.md`** (não regra-irmã): o domínio depende de `caps`/`route`/`run`/`policy-eval`/`adopt` e do sinal `BROWSER_LOGIN_REQUIRED`, todos já no primitivo. Ship via regra ⇒ runtime-neutro (Codex herda) + consumers herdam via harness-sync. O anti-padrão ("afirmar incapacidade sem verificar") é o mesmo já proibido por `runtime-capabilities.md` noutro domínio — o fix **estende disciplina existente**, não inventa capacidade nova.

4. **Boundary anti-overcorrection (crítico — o Turnstile prova que alguns handoffs são corretos).** A regra NÃO é "nunca delegar". Delega-se só o **menor subpasso comprovadamente humano, APÓS tentativa real**. Critério operacional de "realmente tentou" (redação do Codex, mais afiada que a minha): rodou `route`/`caps`; se `primary`, carregou a URL e tentou a ação relevante **até o primeiro blocker concreto**; respeitou `policy-eval`/`run --confirm` em fluxo mutante/sensível; auth → emitiu `BROWSER_LOGIN_REQUIRED: <host>`; Turnstile/CAPTCHA/2FA/pagamento/ação irreversível → **observado no browser, não inferido pela presença teórica do widget**. O handoff resultante carrega a evidência ("carreguei e submeti via agent-browser; o Turnstile managed bloqueou; preciso só do submit humano — eu confirmo o lead via Supabase depois").

**Disagreements / minority report.** Nenhum desacordo de direção. Dois refinamentos do Codex que adoto e registro como tais (não load-bearing, mas valiosos):
- (a) **Espelhar uma frase curta no bloco gerenciado** de `CLAUDE.md`/`AGENTS.md` ("antes de handoff humano de browser, tente ou prove indisponibilidade/blocker com agent-browser e delegue só o subpasso bloqueado") para visibilidade — a fonte canônica permanece o rule file sincronizado pelo harness. Decisão: incluir como uma linha no índice managed, opcional.
- (b) **Reopen-trigger (rule-of-three) deferido** para um output-linter hook: se *após* a regra surgirem ≥3 novos punts especulativos com padrão textual parecido E a última-msg+audit forem expostos de forma estável com baixo falso-positivo, reconsiderar um `Stop`/output-lint hook. Fica marcado `unresolved` no ledger de propósito — é o gate de demanda, não trabalho a fazer agora.

**Objeção mais forte à posição vencedora (preservada):** regra-only pode apodrecer porque o reflexo vive *dentro* do modelo, fora do alcance de qualquer mecanismo determinístico. Mitigação aceita: começar pela regra evidenciável (um hook frágil em NL criaria confiança falsa e atrito onde o handoff é correto) e deixar o reopen-trigger (b) armado para escalar se a regra não pegar.

**Recommended next step: graduate.** Trabalho pequeno e bem-delimitado (1 seção de regra + 1 linha no bloco managed), mas mexe em regra compartilhada que sincroniza pra consumers — qualifica para um `/sdd` enxuto com a seção redigida + um exemplo de "antes/depois" do handoff (o caso cognixse é a fixture). Alternativa: aplicar a edição direto (é curta e o desenho está fechado) e pular o overhead de spec. O humano decide entre **graduate-to-SDD** e **aplicar-direto**.

