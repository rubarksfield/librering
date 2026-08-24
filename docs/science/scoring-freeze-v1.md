# LibreRing scoring V1 freeze

Approval date: 2026-08-24  
Status: **approved for production implementation; not clinically validated**  
Specification: `scoring-model-v1.md`

The V1 freeze preserves the exact formulas, weights, protected states, confidence
logic, exclusions, and limitations that passed the deterministic research suite.
Approval does not establish physiological accuracy, medical validity,
demographic fairness, or physical R12 validation.

Source integrity at approval:

```text
6f506fe9d0bc76d621344744bf14f14ce6a999f1cdc4f65daf0f347ef5be9d08  scoring-model-v0.1.md
5766f8e96b64c46e140ea50a9c58654a560b9e47b154d9de81f5531720a1eea2  models/cycle-context-model-card.md
e70cdab820410231fd73854f7757dcec767696f58e6f867856bd78394ff52d6b  models/movement-model-card.md
87e66ae3dbc6a76739323555b16cbe95ebff21ca5a1df7ae0794062b4fe3b564  models/recovery-model-card.md
de810acdd7726d74a576db287e9000b56ef098c2bb80a6c4d334a3a292286a48  models/sleep-model-card.md
45d294d2b7888eb1015c394fe5ac33a63a8f4cf67573293ccf13db754eca0973  ../../research/scoring/outputs/manifest.json
f9789bce84ec74fbd96672330e260c03742badb74cfd16166b3e0d26ac5b65d6  ../../research/scoring/synthetic_data/scenarios.jsonl
```

Any production formula change requires a new version, scenario/test update,
documented rationale, and migration strategy. Implementation must fail closed on
critical missing data and keep unsupported R12 metrics at zero weight.

Approved V1 artifacts:

```text
0a587ff79a022057e1bc7cbf90f4cff9e358bfdb198f54573423b1e9ec804575  scoring-model-v1.md
c780f170e1ec99823af62278b95e28f682160d6778cdb530d57b5529c28ef6c4  v1/model-cards/cycle-context-model-card.md
c05ba32dc42474d384097a0198f6f6859c33bfa85418d6c4d0710b3150f290ab  v1/model-cards/movement-model-card.md
ef22d0b5b7f1e1cad19249c4aee43ebcf0ab92af2459d3cb46ceead69048b1c4  v1/model-cards/recovery-model-card.md
5fca92cf032259451a2633b34e93fdb072227846369ba7a34aa6c660824a9cef  v1/model-cards/sleep-model-card.md
```
