# 🌊 SHIPPING AGENT AUTOMATION – Narrative Spec

## 🎯 Objective

สร้างระบบ Quotation Intelligence สำหรับบริษัท Shipping Agent เพื่อให้สามารถสร้างใบเสนอราคา (PDA/FDA) อัตโนมัติจาก historical data เดิม โดยอ้างอิงค่าใช้จ่ายจริงในแต่ละ port และเงื่อนไขการเทียบท่าของเรือ

## 🧩 Scenario Overview

บริษัทเราทำหน้าที่เป็น ship agent สำหรับเรือ chemical tanker เช่น MT. DING HENG 30, DING HENG 31, FOCUS STAR ฯลฯ

ทุกครั้งที่เรือเข้าเทียบท่าในไทย เช่น Map Ta Phut (MTT, TTT) เราต้องจัดทำใบ Proforma Disbursement Account (PDA) ซึ่งเป็น “ใบเสนอราคา” ที่แสดงค่าใช้จ่ายคาดการณ์ทั้งหมดที่เจ้าของเรือจะต้องจ่าย

และหลังจากเสร็จงาน เราจะมีใบ Final Disbursement Account (FDA) เป็น “ใบสรุปค่าใช้จ่ายจริง” ที่ใช้ปิดบัญชี

เราต้องการให้ระบบ “เรียนรู้” จาก FDA เหล่านี้ แล้วสามารถ generate PDA ใหม่ได้อัตโนมัติเมื่อมีเรือ call เข้ามา

## 📄 Example: Real Case

### A. FDA Example – MTT (Shifting Port)

| Section         | Detail                    |
| :-------------- | :------------------------ |
| **Vessel**      | MT. DING HENG 30 VOY 2518 |
| **Port**        | MTT, Map Ta Phut          |
| **LOA**         | 112 m                     |
| **GRT**         | 4,626 T                   |
| **DRAFT**       | 6.5 m                     |
| **Is Shifting** | ✅ True                   |
| **Total**       | **148,407 THB**           |

**Breakdown:**

| Item      | Amount (THB) | Formula (in text)                                 |
| :-------- | :----------- | :------------------------------------------------ |
| Tug Hire  | 92,876       | 0.5 × GRT × 3 tugs + oil surcharge @3350/hr + VAT |
| Rope Boat | 5,567        | THB 2,500/hr × 5 hrs + oil @1340/hr               |
| Pilotage  | 12,543       | (LOA/ft - 5) × (draft/ft) × 10% × 50%             |
| Clearance | 2,000        | Customs + Immigration + Harbour fee               |
| Formality | 5,440        | fixed as per principal                            |
| **Total** | **148,407**  |                                                   |

### B. FDA Example – TTT (Main Port)

| Section         | Detail                    |
| :-------------- | :------------------------ |
| **Vessel**      | MT. DING HENG 30 VOY 2518 |
| **Port**        | TTT, Map Ta Phut          |
| **LOA**         | 112 m                     |
| **GRT**         | 4,626 T                   |
| **DRAFT**       | 6.5 m                     |
| **Is Shifting** | ❌ False                  |
| **Total**       | **303,519 THB**           |

**Breakdown:**

| Item                | Amount (THB) | Formula (in text)                           |
| :------------------ | :----------- | :------------------------------------------ |
| Port Due            | 39,599       | (THB 8 × GRT) + 7% VAT                      |
| Tug Hire            | 116,095      | 0.5 × GRT × 2 tugs + oil surcharge @3350/hr |
| Rope Boat           | 6,078        | 2 moves × 1,500/move + oil @536/hr          |
| Pilotage            | 12,543       | same as above                               |
| Clearance           | 2,000        | same as above                               |
| Authority Transport | 25,600       | fixed                                       |
| Port Formality      | 9,600        | fixed                                       |
| Agency Fee          | 38,400       | approved by principal                       |
| **Total**           | **303,519**  |                                             |

## 🧮 Expected Inference Result (Target Output)

**User Input (Spec):**

```json
{
  "port": "Map Ta Phut",
  "is_shifting": false,
  "loa": 112,
  "grt": 4600,
  "vessel_type": "Chemical Tanker"
}
```

**System Output (Generated PDA):**

```json
{
  "quotation": {
    "port": "Map Ta Phut",
    "is_shifting": false,
    "estimated_total": 302500,
    "breakdown": {
      "port_due": 39600,
      "tug_hire": 116000,
      "pilotage": 12500,
      "clearance": 2000,
      "agency_fee": 38400,
      "authority_transport": 25600
    }
  },
  "references": [
    "DING HENG 30 - V2518 (MTT shifting)",
    "DING HENG 30 - V2518 (TTT main)"
  ],
  "reasoning": "Estimated based on similar calls at Map Ta Phut. For non-shifting operation, port due and agency fees apply. Tug hire adjusted for 2 tugs, tariff +2% (2025)."
}
```

## 🧠 How the Agent Decides

- **Matching Agent:** Finds historical FDA entries at same port & vessel size. Detects two patterns: shifting vs non-shifting.
- **Pattern Builder Agent:** Learns average cost per category.
- **Tariff Verifier:** Queries latest tariff from Firestore.
- **Explanation Agent:** Generates reasoning string summarizing source & adjustment.
- **Output Writer:** Writes PDA JSON + PDF draft.

## ⚙️ Technical Story (Flow Integration)

```text
                USER INPUT (spec)
                        │
                        ▼
        ┌───────────────────────────────────┐
        │     INFERENCE FLOW (ADK)          │
        │───────────────────────────────────│
        │ Matching → Pattern → Tariff → NLP  │
        └──────────────┬────────────────────┘
                       │
                       ▼
              KNOWLEDGE CORE
             (Firestore + Vertex Matching Engine)
                       ▲
                       │
        ┌──────────────┴────────────────────┐
        │      INGESTION FLOW (ADK)         │
        │ OCR → Extract → Formula → Store   │
        └───────────────────────────────────┘
                        │
                        ▼
                 FDA PDF Upload
```

---

# 🧠 AGENT SPECIFICATION DOCUMENT

**(for Google ADK + Firebase + Vertex Matching Engine stack)**

## 🩵 I. INGESTION PIPELINE: “เรียนรู้จาก FDA จริง”

### Ingestion Flow

```text
           ┌────────────────────────────────────────┐
           │         📂 FDA PDF Upload (GCS)         │
           └────────────────────────────────────────┘
                             │ (Cloud Function Trigger)
                             ▼
           +------------------------------------------------+
           | 🧠 OCR & Parser Agent (Gemini 2.5 Flash)       |
           | Extract text + layout + detect sections        |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 📊 Cost Extractor Agent                        |
           | Parse "PORT EXPENSE", amounts & formulas        |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 🧮 Formula Interpreter Agent                    |
           | Convert natural formula → JSON rule             |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 🏷️ Condition Tagger Agent                      |
           | Identify context (port, shifting, LOA, GRT)     |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 🧩 Schema Harmonizer Agent                      |
           | Merge data → unified structure                 |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 💾 Knowledge Updater Agent                     |
           | - Save structured doc to Firestore             |
           | - Create embedding → Vertex Matching Engine     |
           +------------------------------------------------+
```

### Ingestion Agent Definitions

**1. fda_ingest_orchestrator**

- **Purpose:** Main controller ที่ orchestrate ทุก ingestion step จาก PDF → structured + vectorized record
- **Model:** None (rule-based orchestrator in ADK Flow)
- **Calls:**
  - `ocr_parser_agent`
  - `cost_extractor_agent`
  - `formula_interpreter_agent`
  - `condition_tagger_agent`
  - `schema_harmonizer_agent`
  - `knowledge_updater_agent`
- **Output:** Stored document in Firestore + vector in Matching Engine

**2. ocr_parser_agent**

- **Purpose:** Extract structured text and tables from FDA PDF
- **Input:**
  - `pdf_uri: str` (GCS path)
- **Output:**
  ```json
  {
    "sections": {
      "port_expenses": "<raw text>",
      "formality_expenses": "<raw text>",
      "agency_expenses": "<raw text>",
      "remarks": "<raw text>"
    }
  }
  ```
- **Implementation Hint:**
  - Use `vertexai.preview.visionai` or Gemini 2.5 Flash with OCR mode.
  - Save OCR JSON to GCS for reuse.

**3. cost_extractor_agent**

- **Purpose:** Extract each cost item + amount + formula text from OCR result
- **Input:** Output from `ocr_parser_agent`
- **Output:**
  ```json
  {
    "cost_items": [
      {
        "name": "Tug Hire",
        "amount_thb": 92876,
        "formula_text": "0.5 x GRT x 3 tugs + oil surcharge @3350/hr + VAT"
      },
      ...
    ]}
  ```
- **Implementation Hint:**
  - Use Gemini text-to-JSON extraction prompt; pattern match by currency symbol “THB”.

**4. formula_interpreter_agent**

- **Purpose:** Convert natural language cost formula → structured mathematical expression
- **Input:** `formula_text` string(s)
- **Output:**
  ```json
  {
    "formula_parsed": "max(7500, 0.5 * GRT * tugs) + oil_hr * 3350",
    "variables": ["GRT", "tugs", "oil_hr"],
    "rate_ref": "3350/hr"
  }
  ```
- **Implementation Hint:**
  - Use Gemini 2.5 reasoning model with chain-of-thought for symbolic parsing.
  - Fallback: regex templates for known patterns (THB, hrs, VAT).

**5. condition_tagger_agent**

- **Purpose:** Derive contextual metadata about the calling (port, vessel type, shifting, LOA, etc.)
- **Input:** PDF header info text
- **Output:**
  ```json
  {
    "port": "Map Ta Phut",
    "is_shifting": true,
    "vessel": "DING HENG 30",
    "grt": 4626,
    "loa": 112,
    "date": "2025-08-28"
  }
  ```
- **Implementation Hint:**
  - Use rule-based regex + fallback LLM parsing for field extraction.

**6. schema_harmonizer_agent**

- **Purpose:** Merge cost items, conditions, and formulas into unified schema.
- **Input:** All outputs above
- **Output:**
  ```json
  {
    "vessel": "DING HENG 30",
    "voyage": "2518",
    "port": "MTT",
    "is_shifting": true,
    "breakdown": {
      "tug_hire": 92876,
      "pilotage": 12543,
      "clearance": 2000,
      "total": 148407
    },
    "formulas": {
      "tug_hire": "max(7500, 0.5 * GRT * tugs) + oil_hr * 3350"
    }
  }
  ```
- **Implementation Hint:**
  - Define pydantic schema to ensure field consistency before upload.

**7. knowledge_updater_agent**

- **Purpose:** Write structured record → Firestore + push embedding to Vertex Matching Engine
- **Input:** Harmonized record JSON
- **Output:** Firestore document, Matching Engine vector ID
- **Implementation Hint:**
  - Use Firestore Python SDK + Vertex AI Matching Engine API
  - Embed vector = `embedding(port + vessel_type + breakdown summary)`.

### ✅ Ingestion Output Examples

**Firestore (structured)**

```json
{
  "port": "MTT",
  "is_shifting": true,
  "vessel": "DING HENG 30",
  "grt": 4626,
  "loa": 112,
  "breakdown": {
    "tug_hire": 92876,
    "pilotage": 12543,
    "total": 148407
  },
  "formula": {
    "tug_hire": "max(7500, 0.5 * GRT * tugs) + oil_hr * 3350"
  }
}
```

**Vector DB (Vertex Matching Engine)**

- Embedding of → “port + vessel_type + cost pattern summary”

---

## 🧡 II. INFERENCE PIPELINE: “สร้างใบเสนอราคาใหม่”

### Inference Flow

```text
┌────────────────────────────────────────────────────────────┐
│           🧾 User Input (Ship Particular Spec)              │
│   e.g. {port: "Map Ta Phut", shifting: false, LOA:112,...} │
└────────────────────────────────────────────────────────────┘
                             │
                             ▼
           +------------------------------------------------+
           | 🔍 Matching Agent (Vertex Matching Engine)      |
           | Retrieve similar FDA cases (vector similarity)  |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 📊 Cost Pattern Builder Agent                   |
           | Derive mean cost pattern from historical data   |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | ⚖️ Tariff Verifier Agent                        |
           | Adjust cost items using current Firestore tariff|
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 🧠 Explanation Agent (Gemini 2.5 Flash)          |
           | Generate reasoning + reference callings         |
           +------------------------------------------------+
                             │
                             ▼
           +------------------------------------------------+
           | 💾 Output Writer Agent                          |
           | Save new quotation to Firestore / display on UI |
           +------------------------------------------------+
```

### Inference Agent Definitions

**1. quotation_orchestrator_agent**

- **Purpose:** Manage end-to-end flow of quotation generation from spec input.
- **Model:** Gemini 2.5 Flash (planner mode)
- **Calls:**
  - `matching_agent`
  - `cost_pattern_builder_agent`
  - `tariff_verifier_agent`
  - `explanation_agent`
- **Input:**
  ```json
  { "port": "Map Ta Phut", "is_shifting": false, "grt": 4600, "loa": 112 }
  ```
- **Output:** Full quotation JSON with reasoning.

**2. matching_agent**

- **Purpose:** Retrieve similar FDA cases from Vector DB based on vessel & port spec.
- **Input:** User spec JSON
- **Output:**
  ```json
  {
    "matched_cases": [
      { "ref": "DING HENG 30-2518-MTT", "similarity": 0.94 },
      { "ref": "DING HENG 30-2518-TTT", "similarity": 0.92 }
    ]
  }
  ```
- **Implementation Hint:**
  - Use Vertex Matching Engine similarity search on Firestore `vector_id` index.

**3. cost_pattern_builder_agent**

- **Purpose:** Combine matched FDA records → derive typical cost pattern
- **Input:** `matched_cases` + Firestore lookups
- **Output:**
  ```json
  {
    "pattern": {
      "tug_hire": { "mean": 105000, "std": 10000 },
      "pilotage": { "mean": 12500, "std": 0 },
      "port_due": { "mean": 39599 },
      "agency_fee": { "mean": 38400 }
    }
  }
  ```
- **Implementation Hint:**
  - Use NumPy / Pandas in Cloud Function; output fed into next agent.

**4. tariff_verifier_agent**

- **Purpose:** Update prices based on latest tariff in Firestore tariff table.
- **Input:** `pattern` JSON
- **Output:**
  ```json
  {
    "adjusted_breakdown": {
      "tug_hire": 107100,
      "pilotage": 12543,
      "port_due": 41000,
      "agency_fee": 38400
    }
  }
  ```
- **Implementation Hint:**
  - Query Firestore `tariff_rates/{port}/{year}` → multiply or offset.

**5. explanation_agent**

- **Purpose:** Generate natural language reasoning + summary for quotation.
- **Input:** Adjusted cost breakdown + matched references
- **Output:**
  ```json
  {
    "quotation": {
      "total_estimated": 303519,
      "breakdown": { ... }
    },
    "references": ["DING HENG 30-2518-MTT", "DING HENG 30-2518-TTT"],
    "reasoning": "Based on similar callings at MTP port with LOA~112m, GRT~4600T. Adjusted for 2025 tariff (+2%) and non-shifting operation."
  }
  ```
- **Implementation Hint:**
  - Use Gemini 2.5 Flash with summarization prompt; include port, vessel, reason context.

**6. feedback_updater_agent (optional)**

- **Purpose:** When actual FDA (final invoice) uploaded → compare predicted vs actual → fine-tune learning.
- **Output:** update Firestore + retrain vector DB embeddings.

### ✅ Inference Output Example

```json
{
  "quotation": {
    "port": "Map Ta Phut",
    "is_shifting": false,
    "total_estimated": 303519,
    "breakdown": {
      "port_due": 39599,
      "tug_hire": 116095,
      "line_handling": 8560,
      "pilotage": 12543,
      "agency_fee": 38400
    }
  },
  "references": ["DING HENG 30-MTT", "DING HENG 30-TTT"],
  "reasoning": "Based on similar calls at MTP port (LOA~112m, GRT~4600T). Non-shifting operations used 2 tugs. Adjusted 2025 tariff +2%."
}
```

---

## 🔗 III. KNOWLEDGE CORE & SHARED DEFINITIONS

### Knowledge Core Summary

| Layer                  | Tech                    | Role                                   |
| :--------------------- | :---------------------- | :------------------------------------- |
| Firestore              | Document DB             | Structured FDA data per port call      |
| Vertex Matching Engine | Vector DB               | Similarity search for historical cases |
| GCS Bucket             | File Storage            | Raw PDFs + OCR JSON                    |
| BigQuery (optional)    | Analytical Layer        | Aggregation + retraining               |
| Tariff Table           | Firestore subcollection | Latest tariff per port/year            |

### 🗃️ Shared Definitions (Firestore Collections)

**`fda_cases/`**

```json
  "DINGHENG30_2518_MTT": {
    "port": "MTT",
    "grt": 4626,
    "is_shifting": true,
    "breakdown": {...},
    "formulas": {...},
    "vector_id": "abc123"
  }
```

**`tariff_rates/`**

```json
  "MapTaPhut_2025": {
    "tug_hire_multiplier": 1.02,
    "pilotage_rate": 12543,
    "oil_surcharge": 3350
  }
```

---

## 🧩 IV. SYSTEM ARCHITECTURE (Macro View)

```text
                      ┌──────────────────────────┐
                      │  User / Web Frontend     │
                      │ (Quotation Form + Viewer)│
                      └──────────┬───────────────┘
                                 │
                                 ▼
                   ┌────────────────────────────────┐
                   │   Google ADK Flow Engine        │
                   │  (Gemini 2.5 + FlowGraph)       │
                   ├────────────────────────────────┤
                   │  Ingestion Orchestrator Agent   │
                   │  Inference Orchestrator Agent   │
                   └────────────────┬────────────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         ▼                          ▼                          ▼
  ┌────────────────┐        ┌────────────────────┐     ┌──────────────────┐
  │ Firebase / GCS │        │ Vertex Matching Eng │     │ Firestore / BQ  │
  │  (PDF Store)   │        │  (Vector Search)    │     │  (Structured DB)│
  └────────────────┘        └────────────────────┘     └──────────────────┘
```

---

## 🧱 V. DEVELOPMENT GUIDANCE

### Development Checklist

| Layer                  | Tech                                              | Purpose                         |
| :--------------------- | :------------------------------------------------ | :------------------------------ |
| **Flow Logic**         | `google.generativeai.agentframework` (ADK SDK)    | define node-based orchestration |
| **Storage**            | Firestore (`python-firebase-admin`)               | persist structured data         |
| **Vector Search**      | Vertex AI Matching Engine                         | retrieve similar FDA            |
| **OCR**                | Gemini 2.5 Flash (Vision mode)                    | parse PDF                       |
| **Tariff Data**        | Firestore collection `tariff_rates/{port}/{year}` | tariff lookup                   |
| **Frontend**           | Streamlit / Firebase Hosting                      | input + quotation UI            |
| **Auth & IAM**         | Service Account (RLS by principal)                | per-principal access control    |
| **Automation Trigger** | Cloud Functions                                   | trigger ingestion on upload     |
| **Monitoring**         | Cloud Logging + BigQuery audit                    | data lineage and debugging      |

### 💬 Instruction for Developers (Copilot Context)

When implementing:

1.  Agents must understand business semantics:
    - “Shifting” means vessel moves berth → more tugs, less port dues.
    - “Main Port” means initial entry → includes authority & agency fees.
2.  Cost patterns are relative; never output exact past values, always normalize.
3.  The system must explain _why_ the cost is chosen, using the reasoning from FDA references.
4.  Data persistence should be idempotent (avoid re-embedding same FDA twice).

### 🧩 Developer Tips

When implementing Gemini prompts for extraction or reasoning:

- Use 2-shot examples (one shifting, one non-shifting) for stable parsing.
- Always return JSON with deterministic schema for downstream use.
- Keep formula text in both human and machine-interpretable form; future tariff adjustments depend on it.

---

## 📦 VI. PROJECT MANAGEMENT WITH UV

### Overview

This project uses **UV** (Astral's ultra-fast Python package installer and resolver) for dependency management and environment setup. UV provides faster, more reliable dependency resolution compared to traditional pip/poetry workflows.

### Installation & Setup

**Install UV** (macOS):

```bash
brew install uv
```

Or via pip:

```bash
pip install uv
```

**Verify installation:**

```bash
uv --version
```

### Project Structure with UV

```
pda_intel/
├── pyproject.toml          # Project metadata + dependencies (UV config)
├── uv.lock                 # Lock file (deterministic versions)
├── .python-version         # Python version specification
├── src/
│   └── pda_intel/          # Main package
├── tests/
│   └── test_*.py           # Test files
└── README.md               # Project documentation
```

### `pyproject.toml` Configuration

```toml
[project]
name = "pda-intel"
version = "0.1.0"
description = "Quotation Intelligence System for Shipping Agent"
requires-python = ">=3.11"

dependencies = [
    "google-generativeai>=0.3.0",
    "firebase-admin>=6.0.0",
    "google-cloud-aiplatform>=1.40.0",
    "pydantic>=2.0.0",
    "pandas>=2.0.0",
    "numpy>=1.24.0",
    "streamlit>=1.28.0",
    "python-dotenv>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.5.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
index-url = "https://pypi.org/simple"
```

### Common UV Commands

**Create a new project:**

```bash
uv init pda_intel
cd pda_intel
```

**Sync dependencies (install from lock file):**

```bash
uv sync
```

**Add a new dependency:**

```bash
uv add google-generativeai firebase-admin
```

**Add development dependency:**

```bash
uv add --dev pytest black ruff
```

**Remove a dependency:**

```bash
uv remove package-name
```

**Update dependencies:**

```bash
uv lock --upgrade        # Update lock file to latest versions
uv sync                  # Sync environment with updated lock file
```

**Create a virtual environment (optional):**

```bash
uv venv .venv            # Create venv in .venv/
source .venv/bin/activate  # Activate on macOS/Linux
```

**Run Python script with UV:**

```bash
uv run python script.py
```

**Run tests:**

```bash
uv run pytest
```

**Format code:**

```bash
uv run black src/
```

**Lint code:**

```bash
uv run ruff check src/
```

### Workflow Example

```bash
# 1. Clone or initialize project
git clone <repo>
cd pda_intel

# 2. Sync dependencies (creates venv + installs)
uv sync

# 3. Run development work
uv run pytest
uv run black src/
uv run python -m streamlit run src/app.py

# 4. Add a new dependency
uv add google-cloud-logging

# 5. Commit changes
git add pyproject.toml uv.lock
git commit -m "Add google-cloud-logging"
```

### Best Practices with UV

| Practice                         | Details                                                                                            |
| :------------------------------- | :------------------------------------------------------------------------------------------------- |
| **Lock file in version control** | Always commit `uv.lock` to ensure reproducible builds across machines                              |
| **Pin Python version**           | Use `.python-version` to specify exact Python (e.g., `3.11.5`)                                     |
| **Use dev dependencies**         | Separate dev tools (pytest, black, ruff) from production deps in `[project.optional-dependencies]` |
| **Leverage UV for CI/CD**        | Use `uv sync` in GitHub Actions / Cloud Build for fast, deterministic builds                       |
| **Update regularly**             | Run `uv lock --upgrade` monthly; review changes before committing                                  |
| **Use virtual environments**     | Always work within `uv venv` to isolate project deps                                               |

### Integration with Google Cloud (ADK)

When running ADK agents on Cloud Functions or Cloud Run:

```dockerfile
# Dockerfile (Cloud Run)
FROM python:3.11

WORKDIR /app

# Install UV
RUN pip install uv

# Copy project files
COPY pyproject.toml uv.lock ./
COPY src/ ./src

# Install dependencies with UV
RUN uv sync --no-dev

# Run application
CMD ["uv", "run", "python", "-m", "src.main"]
```

### Troubleshooting

| Issue                          | Solution                                                       |
| :----------------------------- | :------------------------------------------------------------- |
| **UV command not found**       | Run `pip install uv` or `brew install uv`                      |
| **Dependency conflicts**       | Run `uv lock --upgrade` to resolve; review `uv.lock` changes   |
| **Slow sync on first run**     | Expected; subsequent runs are cached (much faster)             |
| **Python version mismatch**    | Check `.python-version`; run `uv venv --python 3.11` if needed |
| **Virtual environment issues** | Delete `.venv/` and run `uv sync` again                        |

---

## 🧪 VII. AGENT DEVELOPMENT & TESTING STRATEGY

### Philosophy

Each agent must be developed and tested **independently** with deterministic unit tests before integration. This prevents cascading failures and makes debugging trivial: if integration breaks, we know exactly which agent caused it.

### Development Lifecycle Per Agent

```text
┌──────────────────────────────────────────────────────────────┐
│           1. DEFINE SPEC & TEST CASES                        │
│        (Business logic + edge cases documented)              │
└──────────────────────────────────────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────────┐
│           2. UNIT TEST SUITE (TDD)                           │
│  - Happy path (normal input → expected output)               │
│  - Edge cases (null, empty, boundary values)                 │
│  - Error handling (malformed input, API failures)            │
└──────────────────────────────────────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────────┐
│           3. IMPLEMENT AGENT                                 │
│  (Make tests pass, follow business semantics)                │
└──────────────────────────────────────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────────┐
│           4. RUN LOCAL TESTS                                 │
│  `uv run pytest tests/agents/test_<agent_name>.py -v`        │
└──────────────────────────────────────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────────┐
│           5. TEST WITH REAL DATA (Sandbox)                   │
│  - Use sample FDA PDFs / test Firestore fixtures             │
│  - Validate output schema matches spec                       │
└──────────────────────────────────────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────────┐
│           6. DOCUMENT AGENT BEHAVIOR                         │
│  - Success criteria + examples                               │
│  - Known limitations / assumptions                           │
└──────────────────────────────────────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────────┐
│           7. MARK AS "READY FOR INTEGRATION"                 │
│  (Commit to main, add to integration test suite)             │
└──────────────────────────────────────────────────────────────┘
```

### Agent Test Template

Create `tests/agents/test_<agent_name>.py` for each agent:

```python
import pytest
from src.agents import <agent_name>
from src.schemas import <InputSchema>, <OutputSchema>

class Test<AgentName>Agent:
    """Test suite for <agent_name> agent."""

    @pytest.fixture
    def sample_input(self):
        """Standard input for testing."""
        return {
            "port": "Map Ta Phut",
            "grt": 4626,
            "is_shifting": True,
        }

    @pytest.fixture
    def sample_output(self):
        """Expected output schema."""
        return OutputSchema(
            matched_cases=[
                {"ref": "DING_HENG_30_MTT", "similarity": 0.94}
            ]
        )

    # ✅ HAPPY PATH TESTS
    def test_agent_processes_valid_input(self, sample_input):
        """Agent returns correct output for valid spec."""
        result = <agent_name>_agent(sample_input)
        assert result is not None
        assert isinstance(result, OutputSchema)
        assert len(result.matched_cases) > 0

    def test_agent_output_matches_schema(self, sample_input, sample_output):
        """Verify output matches expected schema structure."""
        result = <agent_name>_agent(sample_input)
        assert result.model_validate(result.dict())  # Pydantic validation

    # ⚠️ EDGE CASE TESTS
    def test_agent_handles_empty_port(self):
        """Agent fails gracefully when port is missing."""
        with pytest.raises(ValueError, match="port is required"):
            <agent_name>_agent({"grt": 4626})

    def test_agent_handles_zero_grt(self):
        """Agent handles GRT = 0 (edge case)."""
        result = <agent_name>_agent({"port": "MTT", "grt": 0, "is_shifting": False})
        assert result.estimated_cost == 0

    def test_agent_handles_boundary_draft(self):
        """Agent handles very shallow/deep draft."""
        for draft in [0.5, 15.0]:
            result = <agent_name>_agent({"port": "MTT", "draft": draft})
            assert result is not None

    # 🚨 ERROR HANDLING TESTS
    def test_agent_handles_api_failure(self, monkeypatch):
        """Agent handles Firestore/API timeout gracefully."""
        def mock_firestore_error(*args, **kwargs):
            raise ConnectionError("Firestore timeout")

        monkeypatch.setattr("src.agents.firestore_call", mock_firestore_error)
        with pytest.raises(ConnectionError, match="Firestore timeout"):
            <agent_name>_agent({"port": "MTT"})

    def test_agent_handles_malformed_json(self):
        """Agent rejects invalid input JSON."""
        with pytest.raises(ValueError, match="Invalid input"):
            <agent_name>_agent("not a dict")

    # 📊 INTEGRATION SANITY CHECKS
    def test_agent_output_is_deterministic(self, sample_input):
        """Same input → same output (no randomness)."""
        result1 = <agent_name>_agent(sample_input)
        result2 = <agent_name>_agent(sample_input)
        assert result1 == result2

    def test_agent_response_time(self, sample_input):
        """Agent responds within SLA (e.g., <2 seconds)."""
        import time
        start = time.time()
        <agent_name>_agent(sample_input)
        elapsed = time.time() - start
        assert elapsed < 2.0, f"Agent took {elapsed}s (SLA: 2s)"
```

### Running Tests Locally

```bash
# Test a single agent
uv run pytest tests/agents/test_ocr_parser_agent.py -v

# Test all agents
uv run pytest tests/agents/ -v

# Test with coverage report
uv run pytest tests/agents/ --cov=src/agents --cov-report=html

# Test and show output (useful for debugging)
uv run pytest tests/agents/test_ocr_parser_agent.py -v -s
```

### Agent Development Checklist

Before marking an agent as "ready for integration":

- [ ] **Spec documented** – Business logic + formulas clearly written
- [ ] **Unit tests written** (happy path + 5+ edge cases)
- [ ] **Tests pass locally** – `uv run pytest` with 100% pass rate
- [ ] **Error handling** – Agent fails gracefully with clear error messages
- [ ] **Schema validated** – Output always matches Pydantic schema
- [ ] **Tested with real data** – Run with sample FDA / Firestore fixtures
- [ ] **Performance acceptable** – Response time < 2s (or agreed SLA)
- [ ] **Code reviewed** – Peer review of logic + test coverage
- [ ] **Documentation complete** – README + inline comments
- [ ] **No external side effects** – Agent doesn't mutate shared state

### Ingestion Pipeline Agent Order

**Develop & test in this sequence** (dependencies must be satisfied first):

1. **`condition_tagger_agent`** ⭐ _Start here_

   - Extracts metadata from PDF header
   - No external dependencies; pure text parsing
   - **Test fixtures:** Sample PDF headers (text only)

2. **`ocr_parser_agent`**

   - Converts PDF → structured text
   - Depends on Gemini API (use mocks in unit tests)
   - **Test fixtures:** Sample FDA PDFs (use `tests/fixtures/sample_fda.pdf`)

3. **`cost_extractor_agent`**

   - Parses cost items from OCR output
   - Input: JSON from `ocr_parser_agent`
   - **Test fixtures:** Generated OCR JSON samples

4. **`formula_interpreter_agent`**

   - Converts formula text → mathematical expressions
   - Input: cost item descriptions
   - **Test fixtures:** Known formula strings + expected outputs

5. **`schema_harmonizer_agent`**

   - Merges all extracted data
   - Input: outputs from agents 1–4
   - **Test fixtures:** Pre-processed agent outputs (mocked)

6. **`knowledge_updater_agent`**

   - Writes to Firestore + Vertex Matching Engine
   - Dependencies: agents 1–5
   - **Test fixtures:** Mock Firestore / Vertex clients

7. **`fda_ingest_orchestrator`**
   - Orchestrates agents 1–6
   - **Integration test:** End-to-end with fixtures

### Inference Pipeline Agent Order

**Develop & test in this sequence:**

1. **`matching_agent`** ⭐ _Start here_

   - Queries Vector DB for similar FDA cases
   - Use mocked Matching Engine responses
   - **Test fixtures:** Pre-seeded Firestore + vector IDs

2. **`cost_pattern_builder_agent`**

   - Aggregates costs from matched cases
   - Input: output from `matching_agent`
   - **Test fixtures:** Sample FDA breakdowns

3. **`tariff_verifier_agent`**

   - Looks up current tariff rates
   - Input: cost pattern from agent 2
   - **Test fixtures:** Firestore tariff table samples

4. **`explanation_agent`**

   - Generates reasoning text
   - Input: all previous outputs
   - **Test fixtures:** Sample cost breakdowns + references

5. **`quotation_orchestrator_agent`**
   - Orchestrates agents 1–4
   - **Integration test:** End-to-end quotation generation

### Integration Testing (After All Agents Ready)

Once all individual agents pass their tests, run **end-to-end integration tests**:

```python
# tests/integration/test_ingestion_flow.py
def test_full_ingestion_pipeline():
    """Test: FDA PDF → Firestore + Vector DB."""
    pdf_uri = "gs://bucket/sample_fda.pdf"
    result = fda_ingest_orchestrator(pdf_uri)

    assert result.firestore_doc_id is not None
    assert result.vector_id is not None
    # Verify Firestore doc exists and is queryable

def test_full_inference_pipeline():
    """Test: User spec → Generated quotation."""
    spec = {
        "port": "Map Ta Phut",
        "is_shifting": False,
        "grt": 4600,
        "loa": 112,
    }
    quotation = quotation_orchestrator_agent(spec)

    assert quotation.total_estimated > 0
    assert quotation.breakdown is not None
    assert quotation.reasoning is not None
```

### Debugging Failed Integration

If integration breaks:

1. **Identify which agent failed** – Check logs for agent name + error
2. **Re-run that agent's unit tests** – Isolate the issue
3. **Check input/output schema** – Verify data format matches
4. **Add mock Firestore fixtures** – Test without cloud dependencies
5. **Run with verbose logging** – `uv run pytest -v -s --log-cli-level=DEBUG`

### Mocking External Services (Unit Testing)

Use `pytest-mock` to avoid cloud calls during testing:

```python
import pytest
from unittest.mock import MagicMock

@pytest.fixture
def mock_firestore(monkeypatch):
    """Mock Firestore for testing."""
    mock_fs = MagicMock()
    mock_fs.collection.return_value.document.return_value.get.return_value.to_dict.return_value = {
        "port": "MTT",
        "grt": 4626,
        "breakdown": {"tug_hire": 92876}
    }
    monkeypatch.setattr("src.agents.firestore", mock_fs)
    return mock_fs

def test_agent_with_mocked_firestore(mock_firestore):
    """Agent works with mocked Firestore."""
    result = matching_agent({"port": "MTT"})
    assert result.matched_cases is not None
```

### Test Coverage Goals

| Component         | Minimum Coverage | Target Coverage |
| :---------------- | :--------------- | :-------------- |
| Agent logic       | 80%              | 95%+            |
| Error handling    | 60%              | 90%+            |
| Schema validation | 100%             | 100%            |
| Integration tests | 60%              | 85%+            |

Check coverage:

```bash
uv run pytest tests/ --cov=src --cov-report=term-missing
```

### Continuous Integration (CI) Setup

Add to `.github/workflows/test.yml`:

```yaml
name: Agent Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: astral-sh/setup-uv@v1
      - run: uv sync --dev
      - run: uv run pytest tests/ --cov=src --cov-report=xml
      - uses: codecov/codecov-action@v3
```

This ensures every commit is tested automatically before merge.

```

```
