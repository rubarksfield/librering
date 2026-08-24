# Approved V1 state matrix

| Domain | Loading | Empty | Partial | Error | Success |
| --- | --- | --- | --- | --- | --- |
| App start | local store opening | first-use welcome | migration/recovery notice | safe retry + diagnostics | last local route or welcome |
| Pairing | scanning/connecting | no rings found | ambiguous firmware | permission/timeout/vendor conflict | identified device + capabilities |
| Sync | domain progress | no retained data | per-domain counts and retry | bounded retry/cancel | idempotent completion |
| Daily | recomputing affected dates | calibrating | supported domains only | last valid summary + issue | one Daily Signal |
| Sleep | loading session | no supported interval | gaps/coverage shown | source issue | result + confidence + evidence |
| Recovery | loading contributors | insufficient critical input | optional contributor omitted | formula/source issue | result or protected state |
| Movement | loading intervals | no valid coverage | manual/imported context shown | source issue | sustainable-context result |
| Trends | loading range | not enough valid days | visible gaps | retry | trajectory + text summary |
| Journal | saving locally | no entries | local draft | validation/storage error | provenance-labelled entry |
| Cycle Context | disabled by default | no logs | calendar estimate only | local recovery path | opted-in, separately controlled data |
| Health export | permission/write progress | no selected records | per-type failures | no silent partial export | counts + stable IDs |
| Deletion | calculating scope | nothing to remove | protected/failed subset | explicit recovery | scope/count confirmation |

Real and demo repositories are separate. Demo state is deterministic and can
never be merged into, exported with, or mistaken for real user data.
