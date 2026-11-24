# b_split.py – Read Scans and Split Document Bundles

Ek scanned PDF mein multiple papers ho sakte hain. Ye script scan pages ka text nikalti hai aur headings ke basis par unhe individual papers mein split karti hai.

## 1. Scanned page ka text
- `TRANSCRIBE_PROMPT` Gemini ko bolta hai ki page ka text top-to-bottom copy kare, tables mein cells ko `|` se separate kare, numbers exactly copy kare aur unreadable text ko `[illegible]` likhe.
- `transcribe(png)` image ko Base64 banakar Gemini ko bhejta hai aur transcription return karta hai.
- `page_texts(path)` `read_document()` se dekhta hai kaunse pages ko vision chahiye. Aise pages ko `render_page_png()` se image banata hai aur `cached("vision", ...)` se transcription save/reuse karta hai.
- Return: page-wise text aur source `"text"` ya `"vision"`.

## 2. Papers split karna
- `TITLES` mein known headings hain: Certificate of Analysis, E-way Bill, Packing List, Lorry Receipt/Consignment Note aur Invoice.
- `title_kind(text)` first 8 non-empty lines mein heading search karta hai.
- `split_papers(pages)` page order mein chalta hai. Known title mile toh naya paper start; title na mile toh page previous paper ka continuation hota hai. First page unknown ho toh `other` banta hai.

## 3. Main flow
Har selected file ke liye:
1. Government JSON already structured ho toh uska type print karke aage badhta hai.
2. Otherwise page text nikalta hai.
3. `split_papers()` se paper type aur page ranges find karta hai.
4. File, source, page count aur detected papers print karta hai.

**Connection:** `common.py` cache/model/hash helpers deta hai; `app/ingestion/readers.py` reading aur page rendering deta hai. `c_check.py` is file ke `page_texts()` aur `split_papers()` ko reuse karta hai.

**Takeaway:** `b_split.py` scans ko text mein badalta hai aur ek bundle ko individual papers mein todta hai.
