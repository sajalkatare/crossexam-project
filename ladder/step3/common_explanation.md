# common.py – Shared Helpers

`common.py` mein Step 3 ki scripts ke reusable helper functions hain.

- `CACHE`: `data/cache` folder jahan model outputs JSON files mein save hote hain.
- `SHIPMENTS`: Demo mein `0002` aur `0010` prefixes wali shipments select hoti hain.
- `paper_files()`: `demo-data/files` se selected shipment files return karta hai.
- `all_papers()`: Folder ki saari files return karta hai.
- `fingerprint(data)`: File bytes ka SHA-256 hash banata hai.
- `cached(group, key, make)`: Cache file milne par saved result deta hai; nahi toh `make()` chalakar result save karta hai. Second run par model call bach sakti hai.
- `chat_model()`: `MODEL_SMALL` environment variable se Gemini model leta hai; default `gemini-3.5-flash-lite`.

**Connection:** Baaki Step 3 scripts is file ko file selection, hashing, caching aur Gemini setup ke liye use karti hain.

**Takeaway:** `common.py` shared toolbox hai.
