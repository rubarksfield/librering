# Complete user-flow definition

Each row records the minimum happy path; failures branch to explicit recovery, not
silent retry. “Hidden” means deliberately deferred from that flow, not unavailable.

| Flow | Goal / entry | Minimum steps and decisions | Error/recovery | Exit / required information / deliberately hidden |
| --- | --- | --- | --- | --- |
| Welcome | Understand product on first launch | Open → privacy promise → Continue | local storage unavailable: explain and stop | privacy/no-account/R12-limit understood; formulas hidden |
| Demo mode | Explore without ring | Welcome → Try demo | persistent Demo label; reset demo available | realistic fictional Today; pairing mechanics hidden |
| Bluetooth permission | Grant only when needed | Pair → rationale → system prompt | denied: settings path and demo | permission purpose/state shown; protocol hidden |
| Scan | Find nearby ring | Scan → bounded progress | timeout: fit/charge/QRing checklist → retry | discovered candidates + signal/identity confidence; UUIDs hidden |
| Ring selection | Choose correct device | select `COLMI R12_*` → confirm physical display/name | multiple/unknown: identify one at a time | selected name/address privacy note; raw advertisements hidden |
| Protocol identification | Refuse unsupported device | automatic capability probe | mismatch: Unsupported firmware + diagnostic export | supported capability list; command bytes hidden outside Developer Mode |
| Initial sync | Import without duplicates | Connect → clock check → progress | partial: preserve completed ranges, resume | exact range and last success; packet count hidden |
| First useful day | Avoid empty-dashboard punishment | first sync → available Today | insufficient history: Calibration explanation | current reliable values + learning state; scores needing baseline hidden |
| Calibration | Explain learning | domain card → What is learning? | device/firmware change: Recalibrating | days/requirements and no retrospective surprise; algorithms at Inspect |
| Good sleep | Understand support | Today → Sleep | none | main reason, confidence, action; stages deeper |
| Poor sleep | Understand limitation without blame | Today → Sleep Explain | disagreement: edit interval/leave note | duration/continuity reason; medical conclusions hidden |
| Incomplete sleep | Avoid false score | Today issue → data explanation | retry sync / fit / battery paths | no result, captured data and next step; error codes hidden |
| Low Recovery | Understand why | Today → Recovery Explain | missing pulse: provisional state | changed signals + optional check-in; opaque HRV hidden |
| Normal Recovery | Confirm normal | Today → Recovery Explain | subjective disagreement shown | personal range + confidence; no “push harder” command |
| Swim logging | Count unseen activity | Today Log → Swim → pool/open water → duration/effort → Save | cancel preserves nothing; invalid duration inline | manual provenance + unsupported list; laps/SWOLF/pace absent |
| Imported swim | Accept trusted source | import event → review → Save | duplicate merge preview | source/time/duration; unsupported ring metrics absent |
| Ring-recorded swim | Handle only if capability exists | not available for R12 | feature absent, never disabled theatre | explicit unsupported state in docs; no fabricated UI |
| Weekly trend | Answer direction | Trends → domain → 7d | low coverage: gap note | improving/stable/mixed + coverage; raw samples deeper |
| Metric explanation | Learn one value | Explain row → definition | unavailable semantics: say unknown | source/unit/window/meaning; protocol jargon Developer Mode only |
| Journal entry | Add context | Today Log → note/check-in → Save | sensitive preview settings | timestamp/source/edit/delete; no causal claim |
| Disconnect | Restore connection | Ring issue → Retry | bounded failure → diagnostics/unpair | data-preservation status and next step; UUIDs hidden |
| QRing conflict | Release BLE ownership | issue → Close QRing instructions → Retry | still busy: OS Bluetooth/reset steps | likely cause framed as possibility; no blame/force close action |
| Low battery | Avoid missed night | header warning → charge guidance | warning dismissed until meaningful threshold | %, expected data impact; notification mechanics hidden |
| Partial sync | Resume idempotently | issue → Resume | repeated failure → preserve + export diagnostics | completed and missing ranges; packet details hidden |
| Unsupported firmware | Fail closed | identity probe → unsupported | export diagnostics / stay unpaired | model/firmware + unsupported reason; no fallback characteristic |
| Health permission | Granular platform consent | You Data → platform → record categories → system prompt | denied: local app still works | read/write categories and provenance; unavailable OS items absent |
| Export | Own data | You → Data → Export → format/scope → preview → Save | disk/share failure: retry without regeneration | rows/range/format/checksum; internals hidden |
| Delete selected | Remove scope | You Data → scope → consequences → confirm | authentication/OS interruption: no deletion | deleted/retained readback; technical SQL hidden |
| Delete all | Full local reset | You Data → Delete all → type confirmation → delete | cancellation is safe; failure leaves audit | completion and backup caveat; no dark pattern |
| Unpair | Disconnect while preserving choice | You Ring → Unpair → keep/delete data | BLE unavailable does not block local unpair | device relation removed; data decision explicit |
| Developer Mode | Inspect protocol by choice | You About → enable → warning | easy disable | services/logs/redaction/export; never on daily UI |
| Cycle Context opt-in | Consent without coercion | You → Cycle Context → privacy → mode(s) → Enable | skip leaves feature absent | local/separate-delete/no inference; fertility claims absent |
| Cycle logging | Log period/symptom | Today Log → period/symptom → date/details → Save | edit/delete available | user-entered provenance + calendar estimate label |
| Pregnancy declaration | Change context sensitively | Cycle Context → Follow pregnancy → privacy → due-date method → Enable | “pregnancy ended” includes loss-sensitive options | trend-only state and clinical limitation; no inferred announcement |
| Reproductive deletion | Delete separately | You Cycle → Delete data → preview → confirm | failure preserves data and reports | only reproductive rows removed; rest of app retained |

## Flow invariants

- No retry deletes or duplicates a previously verified record.
- A denied permission never disables unrelated local use.
- Unsupported firmware cannot fall through to guessed characteristics.
- Any destructive action previews exact scope and confirms completion by readback.
- Reproductive data has a separate deletion path and notification privacy default.
