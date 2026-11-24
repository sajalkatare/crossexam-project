# Step 3 – Complete Flow and File Connections

## Overall flow

```text
demo-data/files/
      |
      v
a_read.py       File format aur reading method identify
      |
      v
b_split.py      Scan text (vision if needed) + paper splitting
      |
      v
c_check.py      Form extraction + rule-based validation
      |
      v
d_group.py      Strong identifiers se shipment-wise grouping
      |
      v
e_match.py      Invoice vs PO / GRN / product master matching
      |
      v
Issues + route + payable amount + debit note amount
```

## Har file ka kaam

| File | Simple kaam |
|---|---|
| `common.py` | Shared helpers: file selection, SHA-256, cache, Gemini model |
| `a_read.py` | File format check; direct text/JSON ya vision ki zaroorat identify |
| `b_split.py` | Scan ka text nikalna aur bundle ko individual papers mein split karna |
| `c_check.py` | Matching form fill karna aur validation chalana |
| `d_group.py` | Strong identifiers se related papers ko same shipment mein group karna |
| `e_match.py` | Grouped papers ko PO, GRN aur product master se match karna |

## Files ka connection

```text
common.py
  ├── a_read.py
  ├── b_split.py
  ├── c_check.py
  ├── d_group.py
  └── e_match.py

a_read.py -> app/ingestion/readers.py

b_split.py -> common.py + app/ingestion/readers.py

c_check.py -> b_split.py + common.py
              + app/schemas.py + app/rules/validation.py

d_group.py -> c_check.py + common.py
              + app/rules/grouping.py + app/rules/normalize.py

e_match.py -> c_check.py + d_group.py
              + demo-data/master.json
              + demo-data/ground_truth.json
              + app/rules/match_engine.py
              + app/rules/normalize.py
```

## AI vs normal code

| Task | Kaun karta hai? |
|---|---|
| File format/readability identify | Reader code |
| Scanned page ka text copy | Gemini vision (`b_split.py`) |
| Page boundaries se papers split | Heading rules (`b_split.py`) |
| Paper ka structured form fill | Gemini (`c_check.py`) |
| Extracted form validate | Python rules (`c_check.py`) |
| Papers ko shipment-wise group | Strong-key rules (`d_group.py`) |
| Invoice ko PO/GRN se match | Matching engine (`e_match.py`) |

## Cache
`common.py` ka `cached()` helper outputs ko `data/cache/` mein save/reuse karta hai:
- `b_split.py`: vision transcription.
- `c_check.py`: extracted forms.

Same input dobara run karne par cached output reuse ho sakta hai, isliye repeated model calls bachti hain.

## Windows PowerShell commands

Project root se:

```powershell
.\run.bat ladder/step3/a_read.py
.\run.bat ladder/step3/b_split.py
.\run.bat ladder/step3/c_check.py
.\run.bat ladder/step3/d_group.py
.\run.bat ladder/step3/e_match.py
```

Demo checks:

```powershell
.\run.bat ladder/step3/c_check.py --misread
.\run.bat ladder/step3/c_check.py --bad-po
```

## Final takeaway

**Step 3 = Read → Split → Extract & Validate → Group → Match.**

Pehle documents read hote hain, phir bundles individual papers mein split hote hain, unka data forms mein extract/check hota hai, related papers shipment-wise group hote hain aur finally invoice PO/GRN ke against match hota hai.
