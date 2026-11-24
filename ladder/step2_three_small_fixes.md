# Step 2 -- Three Small Fixes in the Invoice Extraction Agent

## 1. Step 2 ka main idea

Step 1 mein humne ek simple LangChain agent banaya tha. Hum file dete
the aur agent us file se invoice ki details nikalta tha.

Lekin Step 1 mein teen practical problems thi:

1.  **Har document ko invoice samjha ja raha tha.** COA, e-way bill,
    packing list jaise documents ka format invoice se alag hota hai.
2.  **Same file dobara process ho sakti thi.** Script ko yaad nahi rehta
    tha ki file pehle process hui hai ya nahi.
3.  **Crash hone par results lose ho sakte the.** Results sirf
    processing ke end mein save hote, toh beech mein crash hone par
    pehle ke results bhi lose ho sakte the.

Step 2 mein hum in teen problems ko solve karte hain. Abhi bhi **sirf ek
Python script** hai --- koi queue, database server ya web application
nahi.

## 2. Step 1 vs Step 2 -- kya change hua?

  -----------------------------------------------------------------------
  Problem in Step 1       Step 2 ka fix           Simple meaning
  ----------------------- ----------------------- -----------------------
  Har paper ko invoice    Pehle document ka type  Invoice, shipping
  form mein extract karna identify karo           document, certificate
                                                  ya other

  Same file baar-baar     SHA-256 fingerprint     Pehle se dekhi hui
  process ho sakti thi                            exact file ko skip karo

  Crash hone par results  JSONL file mein turant  Har successful result
  lose ho sakte the       save                    ko immediately disk par
                                                  likho
  -----------------------------------------------------------------------

## 3. Imports -- naye tools kyun chahiye?

``` python
import hashlib
import json
import os
import sys
from typing import Literal
```

  -----------------------------------------------------------------------
  Library                             Kaam
  ----------------------------------- -----------------------------------
  `hashlib`                           File ka SHA-256 fingerprint banata
                                      hai

  `json`                              Result ko JSON format mein
                                      save/read karta hai

  `os`                                File existence, filename aur
                                      environment variables handle karta
                                      hai

  `sys`                               Command line se diye gaye file
                                      paths read karta hai

  `Literal`                           Allowed document types ko restrict
                                      karta hai
  -----------------------------------------------------------------------

Baaki imports --- LangChain, Gemini aur Pydantic --- Step 1 ki tarah
agent aur structured output ke liye hain.

``` python
from step1_one_agent import Invoice, read_file
```

Iska matlab: Step 1 ka `Invoice` form aur `read_file()` function reuse
ho raha hai. Humein unka code dobara likhne ki zaroorat nahi.

**Important:** Step 1 delete ya replace nahi hua. Step 2 uske upar naye
features add karta hai.

## 4. Model aur result file

``` python
MODEL = ChatGoogleGenerativeAI(
    model=os.environ.get("MODEL_SMALL", "gemini-3.5-flash-lite")
)

SAVED = os.environ.get("STEP2_RESULTS", "ladder/results.jsonl")
```

-   `MODEL`: Gemini model select karta hai. Agar `MODEL_SMALL`
    environment variable set hai, toh uski value use hogi. Nahi toh
    default model `gemini-3.5-flash-lite` use hoga.
-   `SAVED`: Results save karne wali file ka path hai. Default location
    `ladder/results.jsonl` hai.
-   `STEP2_RESULTS` environment variable se result file ka path change
    bhi kar sakte hain.

Yahan `.jsonl` ka matlab **JSON Lines** hai: har document ka result ek
alag line mein JSON object ke form mein save hota hai.

Example:

``` json
{"file":"invoice.pdf","sha256":"abc123...","kind":"invoice","fields":{"invoice_number":"INV-101"}}
{"file":"coa.pdf","sha256":"def456...","kind":"certificate","fields":{"batch_number":"B-22"}}
```

Actual SHA-256 values kaafi lambi hoti hain; yahan example ke liye short
rakhi gayi hain.

## 5. Fix 1 -- Pehle document ka type identify karo

### Problem

Step 1 mein har document ko `Invoice` schema ke according read kiya ja
raha tha.

Lekin alag documents mein alag information hoti hai:

-   Invoice: invoice number, PO number, total amount
-   E-way bill / packing list / lorry receipt: invoice number, vehicle
    number
-   Certificate of Analysis (COA): batch number, expiry date, test
    result

Agar COA ko invoice form mein extract karenge, toh useful information
miss ho sakti hai.

### 5.1 Document type identify karne ka form

``` python
class Kind(BaseModel):
    kind: Literal["invoice", "shipping", "certificate", "other"]
```

Ye ek chhota structured-output schema hai. Agent ko document dekhkar in
chaar options mein se ek choose karna hai.

  -----------------------------------------------------------------------
  Kind                                Iska matlab
  ----------------------------------- -----------------------------------
  `invoice`                           Invoice

  `shipping`                          Shipping-related document --- e-way
                                      bill, packing list, lorry receipt

  `certificate`                       Certificate of Analysis (COA) jaise
                                      documents

  `other`                             Jo in categories mein fit nahi hota
  -----------------------------------------------------------------------

`Literal` ensure karta hai ki model allowed values mein se hi ek value
return kare.

### 5.2 Har type ka apna form

``` python
class Shipping(BaseModel):
    invoice_number: str = ""
    vehicle_number: str = ""

class Certificate(BaseModel):
    batch_number: str = ""
    expiry_date: str = ""
    result: str = ""
```

Ab document ke type ke hisaab se relevant fields extract honge.

-   `Shipping` form shipping document ke liye hai.
-   `Certificate` form certificate ke liye hai.
-   `Invoice` form Step 1 se reuse ho raha hai.

`= ""` ka matlab hai: agar document mein woh field nahi milti, toh empty
string return karo.

### 5.3 Form mapping

``` python
FORMS = {
    "invoice": Invoice,
    "shipping": Shipping,
    "certificate": Certificate
}
```

Ye mapping agent ko batati hai ki kaunse document type ke liye kaunsa
form use karna hai.

Example:

  Agent ne type identify kiya   Form use hoga
  ----------------------------- ---------------
  `invoice`                     `Invoice`
  `shipping`                    `Shipping`
  `certificate`                 `Certificate`
  `other`                       Koi form nahi

`other` ke liye mapping nahi hai, isliye us document ke fields `{}`
rahenge.

## 6. `ask()` -- Gemini agent se structured answer lena

``` python
def ask(form, instruction: str, content: list) -> BaseModel:
    agent = create_agent(
        MODEL,
        tools=[],
        system_prompt=instruction,
        response_format=ToolStrategy(form)
    )
    return agent.invoke(
        {"messages": [HumanMessage(content=content)]}
    )["structured_response"]
```

Ye helper function Gemini agent ko ek specific form fill karne ke liye
bolta hai.

Iske teen inputs hain:

-   `form`: Kaunsa schema fill karna hai --- `Kind`, `Invoice`,
    `Shipping` ya `Certificate`.
-   `instruction`: Agent ko kya instruction deni hai.
-   `content`: Document ka content, jo `read_file()` se aaya hai.

`ToolStrategy(form)` ensure karta hai ki response diye gaye Pydantic
schema ke structure mein aaye.

**Simple example:** Pehli baar `ask()` se poochte hain, "Ye kaunsa
document hai?" Doosri baar document type ke matching form ko fill
karwate hain.

## 7. Fix 2 -- SHA-256 se duplicate file skip karna

### Problem

Agar hum same script dobara run karte hain, toh Step 1 same file ko phir
se process karega. Isse unnecessary Gemini API calls aur cost ho sakti
hai.

### 7.1 Pehle se processed files check karna

``` python
def already_done() -> dict:
    if not os.path.exists(SAVED):
        return {}
    return {
        row["sha256"]: row
        for row in map(json.loads, open(SAVED))
    }
```

Is function ka kaam:

1.  Check karta hai ki results file exist karti hai ya nahi.
2.  Agar file nahi hai, toh empty dictionary `{}` return karta hai.
3.  Agar file exist karti hai, toh har JSONL line ko read karke Python
    dictionary mein convert karta hai.
4.  Har result ko uske `sha256` fingerprint ke against store karta hai.

Isse hum quickly check kar sakte hain ki kisi file ka fingerprint pehle
se saved hai ya nahi.

### 7.2 File ka fingerprint banana

``` python
data = open(path, "rb").read()
fingerprint = hashlib.sha256(data).hexdigest()
```

-   `open(path, "rb")`: File ko binary mode mein read karta hai.
-   `hashlib.sha256(data)`: File ke bytes ka SHA-256 hash calculate
    karta hai.
-   `.hexdigest()`: Hash ko readable hexadecimal string mein convert
    karta hai.

**Important:** Fingerprint filename se nahi, file ke actual content se
banta hai.

Iska matlab: - Same content, same filename: same fingerprint. - Same
content, different filename: phir bhi same fingerprint. - Content mein
ek byte bhi change hua: fingerprint usually different hoga.

### 7.3 Duplicate milne par skip

``` python
done = already_done()

if fingerprint in done:
    return {
        **done[fingerprint],
        "skipped": True
    }
```

Agar fingerprint results file mein pehle se mil gaya, toh:

-   Gemini ko dobara call nahi kiya jayega.
-   Purana result return hoga.
-   `skipped: True` add hoga.

`**done[fingerprint]` Python dictionary unpacking hai. Isse purane
result ke saare fields naye dictionary mein copy ho jaate hain.

## 8. Fix 3 -- Har result ko turant save karna

### Problem

Socho 10 files process ho rahi hain. 8 files complete hone ke baad
script crash ho gayi.

Agar results sirf end mein save hote, toh pehli 8 files ka result bhi
lose ho sakta tha.

### 8.1 Result prepare karna

``` python
row = {
    "file": os.path.basename(path),
    "sha256": fingerprint,
    "kind": kind,
    "fields": fields
}
```

Har document ka result ek dictionary mein store hota hai:

  Key        Value
  ---------- ------------------------------------
  `file`     Document ka filename
  `sha256`   File ka unique content fingerprint
  `kind`     Document type
  `fields`   Extracted information

`os.path.basename(path)` full path ke bajaye sirf filename deta hai.

### 8.2 Result immediately append karna

``` python
with open(SAVED, "a") as out:
    out.write(json.dumps(row) + "\n")
```

-   `"a"` ka matlab append mode hai.
-   Naya result file ke end mein add hota hai.
-   `json.dumps(row)` Python dictionary ko JSON string banata hai.
-   `"\n"` next result ko next line par rakhta hai.

**Iska benefit:** Har successful document ka result turant save ho jata
hai. Agar agla document process karte waqt crash hota hai, toh pehle
wale saved results available rahenge.

Note: Ye approach ek simple local file-based persistence hai, full
database ya transaction system nahi.

## 9. `read_paper()` -- poora workflow ek jagah

Ye Step 2 ka main function hai. Ek document ke liye saare teen fixes isi
function mein apply hote hain.

``` python
def read_paper(path: str) -> dict:
    data = open(path, "rb").read()
    fingerprint = hashlib.sha256(data).hexdigest()

    done = already_done()
    if fingerprint in done:
        return {**done[fingerprint], "skipped": True}

    content = read_file(path)

    kind = ask(
        Kind,
        "What kind of paper is this? Look at the whole file.",
        content
    ).kind

    fields = (
        ask(
            FORMS[kind],
            "Fill the form from the paper. Copy values exactly. Leave a field empty if it is not there.",
            content
        ).model_dump()
        if kind in FORMS else {}
    )

    row = {
        "file": os.path.basename(path),
        "sha256": fingerprint,
        "kind": kind,
        "fields": fields
    }

    with open(SAVED, "a") as out:
        out.write(json.dumps(row) + "\n")

    return row
```

Isko simple language mein samjho:

1.  File read karo aur uska SHA-256 fingerprint banao.
2.  Check karo ki ye file pehle process hui hai ya nahi.
3.  Agar pehle process hui hai, toh saved result return karo aur skip
    kar do.
4.  Agar new file hai, toh `read_file()` se uska content nikalo.
5.  Gemini se pehle poochho: "Ye kaunsa document hai?"
6.  Document type ke hisaab se matching form select karo.
7.  Gemini se relevant fields extract karwao.
8.  Result ko `results.jsonl` mein immediately save karo.
9.  Result return karo.

### Ek real-life example

Maan lo input mein ye teen documents hain:

  File             Document type   Extract karne wali information
  ---------------- --------------- -----------------------------------
  `invoice.pdf`    `invoice`       Invoice number, PO number, total
  `coa.pdf`        `certificate`   Batch number, expiry date, result
  `ewaybill.pdf`   `shipping`      Invoice number, vehicle number

Agar `invoice.pdf` dobara run hoti hai aur uska content same hai, toh
script uska saved result return karegi. Gemini se dobara extraction nahi
karwayegi.

## 10. Main block -- multiple files process karna

``` python
if __name__ == "__main__":
    for path in sys.argv[1:]:
        row = read_paper(path)
        print(
            f"{row['file']:24} {row['kind']:12} {row['fields']}"
            + ("   (skipped: seen before)" if row.get("skipped") else "")
        )
```

-   `if __name__ == "__main__"`: Ye code tab run hota hai jab Python
    file directly execute hoti hai.
-   `sys.argv[1:]`: Command line se diye gaye saare file paths leta hai.
-   `for path in ...`: Har file ko ek-ek karke process karta hai.
-   `read_paper(path)`: Upar explain kiya gaya complete workflow run
    karta hai.
-   `print(...)`: Filename, document type aur extracted fields show
    karta hai.
-   `row.get("skipped")`: Check karta hai ki file pehle se processed thi
    ya nahi.

`:24` aur `:12` output ko neatly align karne ke liye formatting widths
hain.

## 11. Step 2 ko run kaise karein?

Original Linux command:

``` bash
./run.sh ladder/step2_three_small_fixes.py demo-data/files/0002_coa_1.pdf
```

Aapke Windows PowerShell + `run.bat` setup mein:

``` powershell
.\run.bat ladder/step2_three_small_fixes.py demo-data/files/0002_coa_1.pdf
```

Multiple matching files run karne ke liye:

``` powershell
$files = Get-ChildItem demo-data/files/0002_*,demo-data/files/0010_* |
    ForEach-Object { "demo-data/files/$($_.Name)" }

.\run.bat ladder/step2_three_small_fixes.py @files
```

`@files` PowerShell array splatting hai. Isse array ke har file path ko
command ke separate argument ke roop mein pass kiya jata hai.

## 12. Output ko kaise samjhein?

Output roughly is tarah dikhega:

``` text
0002_coa_1.pdf          certificate  {'batch_number': 'B-123', ...}
0002_coa_1.pdf          certificate  {'batch_number': 'B-123', ...}   (skipped: seen before)
```

-   First run: document classify aur extract hota hai, phir result save
    hota hai.
-   Second run: same file ka fingerprint milta hai, isliye saved result
    return hota hai aur `skipped: seen before` print hota hai.

Actual extracted values document ke content par depend karenge.

## 13. Important limitations -- abhi kya solve nahi hua?

Step 2 better hai, lekin abhi bhi basic single-script design hai:

-   Results local `results.jsonl` file mein save hote hain; centralized
    database nahi hai.
-   `already_done()` har file process karte waqt poori results file read
    karta hai. Bahut badi file hone par ye slow ho sakta hai.
-   Agar result save karne se pehle crash ho jaye, toh us document ko
    next run mein dobara process karna padega.
-   Same content wali do files ko duplicate maana jayega, chahe unke
    filenames alag hon.
-   `other` type ke documents ke liye abhi extraction form nahi hai;
    `fields` empty `{}` rahega.
-   Results file ka parent folder pehle se exist karna chahiye. Default
    path `ladder/results.jsonl` hai aur project mein `ladder` folder
    available hona chahiye.

## 14. Complete flow -- ek nazar mein

``` text
Input document
      |
      v
Read file bytes
      |
      v
Generate SHA-256 fingerprint
      |
      v
Already processed?
   /       \
 Yes        No
  |          |
  v          v
Return     Read document content
saved           |
result          v
          Ask Gemini: document kind?
                  |
                  v
          Select matching form
                  |
                  v
          Extract structured fields
                  |
                  v
          Save result in results.jsonl
                  |
                  v
              Return result
```

## 15. Step 1 vs Step 2 -- final takeaway

  Capability                             Step 1   Step 2
  -------------------------------------- -------- --------------------
  Read documents                         Yes      Yes
  Extract invoice fields                 Yes      Yes
  Identify document type                 No       Yes
  Use different forms                    No       Yes
  Skip previously processed files        No       Yes, using SHA-256
  Save each result immediately           No       Yes, using JSONL
  Queue / database server / web screen   No       No

> **One-line takeaway:** Step 1 ne document se information extract karna
> sikhaya; Step 2 ne us process ko smarter, duplicate-aware aur crash ke
> baad recover karne layak banaya --- bina system ko complicated kiye.
