# Step 1: Simple Invoice Extraction Agent

## 1. Is code ka purpose

Is code ka simple purpose hai:

**Ek invoice file do → Gemini AI usko read kare → 4 important invoice
fields extract karke structured output de.**

Ye invoice extraction system ka sabse basic version hai. Ismein abhi
queue, database, validation checks, human approval ya UI nahi hai.

Overall flow:

``` text
Input Invoice (PDF / JSON / JPG / PNG)
          |
          v
      read_file()
          |
          v
  Text extract karo ya image banao
          |
          v
   LangChain Agent + Gemini
          |
          v
    Pydantic Invoice Schema
          |
          v
 Supplier, Invoice No., PO No., Total
```

------------------------------------------------------------------------

## 2. Libraries import karna

``` python
import base64
import io
import os
import sys
import time

import pypdfium2 as pdfium
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy
from langchain_core.messages import HumanMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from pydantic import BaseModel
from pypdf import PdfReader
```

  -----------------------------------------------------------------------
  Library                             Kaam
  ----------------------------------- -----------------------------------
  `base64`                            Image/binary data ko Base64
                                      representation mein convert karna

  `io`                                Memory mein temporary buffer banana

  `os`                                Environment variables read karna

  `sys`                               Command-line arguments lena

  `time`                              Execution time calculate karna

  `pypdfium2`                         Scanned PDF pages ko images mein
                                      render karna

  `create_agent`                      LangChain agent create karna

  `ToolStrategy`                      Agent ka output defined schema mein
                                      lena

  `HumanMessage`                      File content ko user message ke
                                      roop mein bhejna

  `ChatGoogleGenerativeAI`            Gemini model connect karna

  `BaseModel`                         Pydantic output schema define karna

  `PdfReader`                         PDF se text extract karna
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 3. Invoice output format define karna

``` python
class Invoice(BaseModel):
    supplier_name: str = ""
    invoice_number: str = ""
    po_number: str = ""
    total: float = 0
```

Ye ek **data schema** hai. Ismein define kiya gaya hai ki AI ko invoice
se kaun-se fields extract karne hain.

  Field              Meaning
  ------------------ -------------------------
  `supplier_name`    Supplier/vendor ka naam
  `invoice_number`   Invoice number
  `po_number`        Purchase Order number
  `total`            Invoice ki total amount

`BaseModel` Pydantic ka base class hai. Ye output ko defined structure
ke according validate/parse karne mein help karta hai.

Default values (`""` aur `0`) tab use hoti hain jab field ki value
available na ho.

------------------------------------------------------------------------

## 4. AI Agent create karna

``` python
agent = create_agent(
    ChatGoogleGenerativeAI(
        model=os.environ.get("MODEL_SMALL", "gemini-3.5-flash-lite")
    ),
    tools=[],
    system_prompt="You read business papers. Fill the invoice form from the paper. Copy numbers exactly.",
    response_format=ToolStrategy(Invoice),
)
```

Ye code ka sabse important part hai. Yahan Gemini-powered LangChain
agent create ho raha hai.

-   **`ChatGoogleGenerativeAI(...)`**: Google Gemini model use karta
    hai.
-   **`MODEL_SMALL`**: Environment variable se model name leta hai. Agar
    variable set nahi hai, toh default `gemini-3.5-flash-lite` use hota
    hai.
-   **`tools=[]`**: Agent ko koi external tool nahi diya gaya.
-   **`system_prompt`**: Agent ko batata hai ki business documents read
    karo aur invoice form fill karo. Numbers exactly copy karo.
-   **`ToolStrategy(Invoice)`**: Agent ka response `Invoice` schema ke
    format mein chahiye.

**Simple meaning:** Ek Gemini-powered agent banao jo invoice read karke
defined 4 fields return kare.

------------------------------------------------------------------------

## 5. File ko AI-readable format mein convert karna

``` python
def read_file(path: str) -> list:
```

`read_file()` file ka path leta hai aur content ko AI message ke liye
suitable format mein return karta hai.

Is function mein JSON, image aur PDF handle hote hain.

### A. JSON file

``` python
if path.endswith(".json"):
    return [{"type": "text", "text": open(path).read()}]
```

JSON file read hoti hai aur uska content text ke roop mein return hota
hai.

### B. JPG / PNG image

``` python
if path.endswith((".jpg", ".png")):
    return [{
        "type": "image_url",
        "image_url": {
            "url": "data:image/jpeg;base64,"
                   + base64.b64encode(open(path, "rb").read()).decode()
        }
    }]
```

-   File ko binary mode (`rb`) mein read karta hai.
-   `base64.b64encode()` binary image data ko Base64 bytes mein convert
    karta hai.
-   `.decode()` Base64 bytes ko normal string mein convert karta hai.
-   `image_url` structure mein image AI ko bhejne ke liye return hoti
    hai.

**Note:** Base64 encoding encryption nahi hai. Ye binary data ko text
representation mein badalne ka tareeka hai.

### C. PDF se text extract karna

``` python
text = "\n".join(
    (p.extract_text() or "")
    for p in PdfReader(path).pages
)
```

-   `PdfReader(path)` PDF open karta hai.
-   `.pages` PDF ke saare pages deta hai.
-   `extract_text()` har page se selectable/readable text nikalta hai.
-   `or ""` ka matlab: agar text extract nahi hua ya `None` mila, toh
    empty string use karo.
-   `"\n".join(...)` sab pages ka text newline ke saath jod deta hai.

``` python
if len(text.strip()) > 40:
    return [{"type": "text", "text": text}]
```

Agar PDF se 40 characters se zyada text mila, toh us text ko AI ko
bhejne ke liye return kar deta hai.

### D. Scanned PDF ko images mein convert karna

Agar PDF se sufficient text nahi mila, toh code assume karta hai ki PDF
scanned/image-based ho sakta hai.

``` python
parts = []

for page in pdfium.PdfDocument(path):
    buf = io.BytesIO()
    page.render(scale=2).to_pil().convert("L").save(buf, format="PNG")

    parts.append({
        "type": "image_url",
        "image_url": {
            "url": "data:image/png;base64,"
                   + base64.b64encode(buf.getvalue()).decode()
        }
    })

return parts
```

Step-by-step:

1.  `parts = []`: Har page ki image store karne ke liye empty list.
2.  `pdfium.PdfDocument(path)`: PDF open karta hai.
3.  `for page in ...`: PDF ke har page par loop chalata hai.
4.  `io.BytesIO()`: Temporary in-memory buffer banata hai.
5.  `page.render(scale=2)`: Page ko 2x scale par render karta hai.
6.  `.to_pil()`: Rendered page ko PIL image mein convert karta hai.
7.  `.convert("L")`: Image ko grayscale banata hai.
8.  `.save(buf, format="PNG")`: Image ko PNG format mein memory buffer
    mein save karta hai.
9.  `buf.getvalue()`: Buffer se image ka binary data leta hai.
10. `base64.b64encode(...)`: Binary image data ko Base64 mein convert
    karta hai.
11. `.decode()`: Base64 bytes ko string banata hai.
12. `parts.append(...)`: Image ko AI input format mein list mein add
    karta hai.
13. `return parts`: Saare PDF pages ki images return karta hai.

**Simple logic:**

-   Text-based PDF → Text extract karke AI ko bhejo.
-   Scanned PDF → Har page ki image bana kar AI ko bhejo.

------------------------------------------------------------------------

## 6. Invoice fields extract karna

``` python
def read_invoice(path: str) -> Invoice:
    result = agent.invoke({
        "messages": [
            HumanMessage(content=read_file(path))
        ]
    })
    return result["structured_response"]
```

Yahan actual AI processing hoti hai.

1.  `read_file(path)`: File ka content read/convert karta hai.
2.  `HumanMessage(...)`: File content ko user message banata hai.
3.  `agent.invoke(...)`: LangChain agent ko request bhejta hai. Agent
    Gemini model se response leta hai.
4.  `result["structured_response"]`: Structured `Invoice` response
    nikalta hai.
5.  `return`: Extracted invoice object return karta hai.

Example output:

``` python
Invoice(
    supplier_name="ABC Technologies",
    invoice_number="INV-1002",
    po_number="PO-5001",
    total=25000.0
)
```

Actual values input invoice par depend karengi.

------------------------------------------------------------------------

## 7. Main block: Program run karna

``` python
if __name__ == "__main__":
    for path in sys.argv[1:]:
        started = time.time()
        print(
            f"{path.split('/')[-1]:24} "
            f"{read_invoice(path)} "
            f"({time.time() - started:.1f} s)"
        )
```

Ye block tab execute hota hai jab Python file directly run ki jaati hai.

-   `sys.argv[1:]`: Command line se diye gaye file paths leta hai.
    `sys.argv[0]` Python script ka naam hota hai, isliye `[1:]` se baaki
    arguments liye jaate hain.
-   `for path in ...`: Har supplied file ko process karta hai.
-   `time.time()`: Processing start/end ka time calculate karne mein
    help karta hai.
-   `read_invoice(path)`: Invoice fields extract karta hai.
-   `print(...)`: Filename, extracted invoice details aur processing
    time print karta hai.
-   `path.split('/')[-1]`: Path se filename nikalta hai.

Run command:

``` bash
./run.sh ladder/step1_one_agent.py demo-data/files/0002_bundle_scan.pdf
```

Is command mein: - `ladder/step1_one_agent.py`: Python script. -
`demo-data/files/0002_bundle_scan.pdf`: Input invoice PDF.

Multiple files bhi arguments mein diye ja sakte hain; loop unhe ek-ek
karke process karega.

------------------------------------------------------------------------

## 8. Complete flow: Ek nazar mein

  -----------------------------------------------------------------------
  Step                    Function / Component    Responsibility
  ----------------------- ----------------------- -----------------------
  1                       `Invoice`               Expected output schema
                                                  define karta hai

  2                       `create_agent()`        Gemini-powered agent
                                                  banata hai

  3                       `read_file()`           File read karke
                                                  text/image input banata
                                                  hai

  4                       `read_invoice()`        Agent ko file content
                                                  bhejkar fields extract
                                                  karta hai

  5                       `__main__`              Files process karta hai
                                                  aur output/time print
                                                  karta hai
  -----------------------------------------------------------------------

## 9. Is Step 1 mein kya hai aur kya nahi?

**Available:** - Ek file ko input dena. - PDF, JSON aur image input
handle karna. - Text-based aur scanned PDF ka basic handling. - Gemini
se invoice fields extract karna. - Pydantic ke through structured output
lena. - Processing time print karna.

**Abhi available nahi:** - Database mein results save karna. -
Background queue ya batch job system. - Invoice validation/business
checks. - Human approval workflow. - User interface/dashboard. - Retry,
monitoring ya error-handling workflow.

## 10. Sabse important takeaway

Ye Step 1 ek basic AI-powered invoice extraction system hai.

**File → Text/Image → LangChain Agent → Gemini → Structured Invoice
Output**

Iska goal pehle ek simple working version banana hai. Baad ke steps mein
database, validation, queues, multiple agents ya human approval jaise
features add kiye ja sakte hain.
