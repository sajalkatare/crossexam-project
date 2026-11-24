# c_check.py – Extract Forms and Validate Them

Ye script har individual paper ka structured data extract karti hai aur phir normal Python rules se basic checks chalati hai.

## Forms
`FORMS` document type ko schema se map karta hai:
- `invoice` → `InvoiceData`
- `packing_list` → `PackingListData`
- `lorry_receipt` → `LorryReceiptData`
- `eway_bill` → `EwayBillData`
- `quality_certificate` → `QualityCertificateData`

Schemas `app/schemas.py` mein hain.

## `fill(kind, text)`
Gemini ko matching schema ke saath call karta hai (`ToolStrategy`) aur structured response ko dictionary mein return karta hai. Instruction hai values exactly copy karo, missing fields empty rakho aur dates `YYYY-MM-DD` mein do.

## `read_papers(path)` flow
1. File bytes read karke `read_document()` call karta hai.
2. Government JSON already structured ho toh code se form leta hai; model call nahi hota.
3. Otherwise `page_texts()` aur `split_papers()` se papers identify karta hai.
4. Har supported paper ke pages ka text combine karta hai.
5. `cached("forms", ...)` se form extract ya saved form reuse karta hai.
6. `validate(kind, form)` se rule-based checks chalata hai.
7. File, kind, form, issues aur extraction source return karta hai.

`by` ka matlab: `code` = direct JSON mapping, `model` = abhi Gemini extraction, `saved` = cached form reuse.

## Validation and demo flags
`validate()` `app/rules/validation.py` mein hai. Code tax ID check digit aur totals/subtotal/tax arithmetic jaise checks kar sakta hai.

- `--misread`: Demo ke liye invoice total mein 1,000 add karke validation dobara chalata hai.
- `--bad-po`: Demo ke liye PO number ka `PO` prefix `PQ` karta hai. Code comment ke mutabik current checks is typo ko catch nahi karte; agle matching step mein ye relevant hai.

**Connection:** `b_split.py` se page text/splitting, `common.py` se cache/model helpers, `app/schemas.py` se forms aur `app/rules/validation.py` se checks milte hain. `d_group.py` iska output use karta hai.

**Takeaway:** `c_check.py` har paper ka form fill karta hai aur extracted data par basic validation chalata hai.
