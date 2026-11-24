# d_group.py – Group Papers into Shipments

Ek shipment ke invoice, e-way bill, packing list, lorry receipt aur COA alag papers ho sakte hain. Ye script strong identifiers ke basis par un papers ko ek shipment group mein jodti hai. Is grouping mein model call nahi hota.

## Strong vs weak keys
- Strong keys: PO number, e-way bill number, supplier + invoice number, batch number. Shared strong key wale papers group ho sakte hain.
- Weak key: Vehicle number. Ek truck multiple shipments carry kar sakta hai, isliye vehicle sirf hint hai; grouping key nahi.

Identifiers normalize bhi hote hain, taaki `SI/26-27/56132` aur `si 26-27 56132` jaise formats ko same maana ja sake.

## `group(papers)`
1. `UnionFind()` grouping structure banata hai.
2. Har paper ke liye `doc_keys(kind, form)` strong aur weak keys nikalta hai.
3. Har paper ko uske strong-key nodes ke saath `union()` karta hai.
4. Connected papers ko same pack mein collect karta hai.
5. Shipment groups return karta hai.

`UnionFind` aur `doc_keys` `app/rules/grouping.py` mein hain.

## `main()`
1. `paper_files()` se files leta hai.
2. `c_check.read_papers()` se extracted papers laata hai.
3. `group()` se shipment-wise groups banata hai.
4. Har group ka invoice PO, paper count aur strong keys print karta hai.
5. `norm_vehicle()` se vehicle numbers normalize karke display karta hai. Vehicle number grouping ke liye use nahi hota.

**Connection:** `c_check.py` extracted papers deta hai; `common.py` file list deta hai; `app/rules/grouping.py` strong-key grouping karta hai; `app/rules/normalize.py` vehicle normalization karta hai. `e_match.py` groups ko aage use karta hai.

**Takeaway:** `d_group.py` related documents ko strong business identifiers se shipment-wise jodta hai.
