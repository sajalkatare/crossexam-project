# e_match.py – Match Invoice with PO and Goods Receipt

Ye final Step 3 script grouped shipment documents ko master data ke against compare karti hai. Invoice mein billed items ko Purchase Order (PO), Goods Receipt (GRN) aur product rules se match kiya jaata hai. Amount ka decision matching code karta hai, AI model nahi.

## Input master data
- `demo-data/master.json`: purchase orders, suppliers, goods receipts aur products.
- `demo-data/ground_truth.json`: expected issue codes, jinke saath demo result compare hota hai.

## `snapshot(members, master)`
Matching engine ke liye `PackSnapshot` banata hai:
1. Group ka invoice form find karta hai.
2. PO number normalize karke master mein matching PO dhoondhta hai.
3. Supplier aur price tolerance leta hai.
4. PO lines ko `POSnapshot` mein convert karta hai.
5. Matching goods receipts ko `GRNSnapshot` mein convert karta hai.
6. Product master se GST rate, COA requirement aur HSN leta hai.
7. Group ke documents ko matching engine ke document format mein convert karta hai.
8. Sab data `PackSnapshot` mein return karta hai.

PO na mile toh PO snapshot `None` aur GRN list empty rehti hai. Default price tolerance 2% hai; supplier-specific value ho toh woh use hoti hai.

## Matching
`run_match(snapshot(...))` `app/rules/match_engine.py` ka function hai. Financial amounts ke liye `Decimal` use hota hai.

Snapshot mein configured checks:
- Price tolerance: supplier master se, otherwise 2%.
- Quantity tolerance: 0%.
- E-way bill value tolerance: 1%.
- Minimum shelf life: 180 days.
- Confidence threshold: 0.8.

## `main()` flow
1. Master aur ground-truth JSON load karta hai.
2. `c_check.py` se papers read karta hai.
3. `d_group.py` se shipment groups banata hai.
4. Har group ka invoice PO nikalta hai.
5. `snapshot()` banakar `run_match()` chalata hai.
6. Route, issue codes, billed amount, payable amount aur debit note amount print karta hai.
7. Individual issue messages print karta hai.
8. Actual issue codes ko ground truth ke expected codes se compare karta hai.

**Connection:** `c_check.py` extracted forms deta hai; `d_group.py` shipment groups deta hai; `master.json` business master data deta hai; `match_engine.py` matching rules chalata hai; `ground_truth.json` expected demo answers deta hai.

**Takeaway:** `e_match.py` invoice ko PO, GRN aur product master se compare karke issues aur payable/debit-note amounts calculate karta hai.
