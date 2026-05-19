# 051 — tasks

Execute top-to-bottom.

## Phase A — Skill: SKILL.md Phase 4 stitch

- [x] A1. Edit `.claude/skills/product/SKILL.md` § Phase 4 step 3 (stitch). Either insert a new substep 3.5 OR extend step 3 with a documented "layout placeholder substitution" block.
- [x] A2. The added text MUST describe: (a) title source priority — brand-book.md `## Product Name` if present else `<idea>` from `.state.json`; (b) lang detection heuristic — `R$ | LGPD | NFS-e | Pix` in concept-brief.md / sitemap.yaml / brand-book.md ⇒ `pt-BR`, else keep `en`; (c) shell-safety note (use python or quoted-delimiter sed because `<idea>` is arbitrary user input).

## Phase B — Skill: delegation-briefs.md screen-writer

- [x] B1. Edit `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer § Next.js stack. Add a CONSTRAINTS bullet about async + `'use client'` separation.
- [x] B2. The bullet MUST contain: (a) the hard rule (`'use client'` MUST NOT appear at top of an `async` page component); (b) the canonical pattern (Server `page.tsx` awaits params, sibling `_<Name>Client.tsx` with `'use client'` owns hooks); (c) the verbatim Next.js runtime error string (`is an async Client Component. Only Server Components can be async at the moment`) so sub-agents can recognize it.

## Phase C — Skill validator

- [x] C1. `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` — exit 0.

## Phase D — Dogfood retro-fix (validation only; /tmp/ not committed)

- [x] D1. Edit `/tmp/dogfood-erp/app/layout.tsx`: title `PROTOTYPE_SLUG` → `ERP para salões de beleza`; lang `en` → `pt-BR`.
- [x] D2. Restructure `/tmp/dogfood-erp/app/check-in/[appointmentId]/page.tsx`: extract client-interactive body to `_CheckInClient.tsx`; leave `page.tsx` as Server async wrapper.
- [x] D3. Same for `/tmp/dogfood-erp/app/prontuario/[clientId]/page.tsx` → `_ProntuarioClient.tsx`.
- [x] D4. Same for `/tmp/dogfood-erp/app/booking/[salonSlug]/page.tsx` → `_BookingClient.tsx`.
- [x] D5. Hard-refresh browser; navigate to `/`, `/check-in/abc123`, `/prontuario/abc123`, `/booking/lumiere-haus`; confirm browser tab title shows the new title; confirm console has 0 React errors on the 3 retro-fixed pages.

## Phase E — Commit

- [x] E1. `git status` + `git diff --stat` — confirm only SKILL.md + delegation-briefs.md + spec 051 scaffold staged.
- [x] E2. Commit with HEREDOC body: `fix(051): /product skill — title placeholder substitution + Next.js async/client rule`.
- [x] E3. `git status` — confirm clean.
- [x] E4. Flip spec 051 `Status:` to `shipped`; check off all boxes in this tasks.md.
