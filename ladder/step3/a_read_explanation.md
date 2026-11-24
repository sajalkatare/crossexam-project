# a_read.py – Choose How to Read Each File

Ye script file ka format inspect karti hai aur batati hai ki file ko kaise read kiya ja sakta hai. Is script mein Gemini call nahi hota.

- Government JSON: code directly structured data read kar sakta hai.
- Digital PDF: file mein text already ho toh directly read hota hai.
- Scan/photo: image se text nikalne ke liye vision model chahiye; ye agle step mein hota hai.

**Flow:**
1. `paper_files()` se shipment `0002` aur `0010` ki files leta hai.
2. File bytes read karta hai.
3. `read_document()` format aur readable text/pages identify karta hai.
4. `result.fmt` detected format batata hai.
5. `pages_needing_vision` batata hai kitne pages ko vision model chahiye.
6. `fingerprint()` file ka SHA-256 banata hai; output mein first 8 characters dikhte hain.
7. `all_papers()` se sab files ka format-wise summary print karta hai.

`read_document()` `app/ingestion/readers.py` mein defined hai.

**Connection:** `common.py` se file helpers leta hai; `app/ingestion/readers.py` ka reader use karta hai. `b_split.py` bhi isi reader ko use karta hai.

**Takeaway:** `a_read.py` decide karta hai file direct text/JSON se read hogi ya scan hone ki wajah se vision chahiye.
