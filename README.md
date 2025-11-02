# PDA Intel - Quotation Intelligence System

UV development setup guide.

## Quick Start

### 1. Install UV (if not already installed)

**macOS:**

```bash
brew install uv
```

**Or via pip:**

```bash
pip install uv
```

### 2. Sync dependencies

```bash
cd pda_intel
uv sync
```

This will:

- ✅ Create a virtual environment
- ✅ Install all dependencies from `pyproject.toml`
- ✅ Generate `uv.lock` (lock file for reproducibility)

### 3. Activate the environment (optional)

UV automatically uses the venv, but you can also activate it:

```bash
source .venv/bin/activate  # macOS/Linux
# or
.venv\Scripts\activate  # Windows
```

### 4. Run tests

```bash
uv run pytest tests/ -v
```

### 5. Run development server

```bash
uv run streamlit run src/pda_intel/ui/app.py
```

## Project Structure

```
pda_intel/
├── pyproject.toml              # Project metadata + dependencies
├── uv.lock                     # Lock file (auto-generated)
├── .python-version             # Python version (3.11.5)
├── README.md                   # This file
├── src/
│   └── pda_intel/
│       ├── __init__.py
│       ├── agents/             # All agents (ingestion + inference)
│       │   ├── ingestion/
│       │   │   ├── ocr_parser.py
│       │   │   ├── cost_extractor.py
│       │   │   └── ...
│       │   ├── inference/
│       │   │   ├── matching.py
│       │   │   ├── cost_pattern_builder.py
│       │   │   └── ...
│       │   └── orchestrators/
│       ├── schemas/            # Pydantic models
│       │   ├── fda.py
│       │   ├── quotation.py
│       │   └── tariff.py
│       ├── services/           # External service wrappers
│       │   ├── firestore.py
│       │   ├── gcs.py
│       │   ├── vector_db.py
│       │   └── gemini.py
│       ├── ui/                 # Streamlit frontend
│       │   └── app.py
│       └── utils/              # Utility functions
│           └── logging.py
├── tests/
│   ├── conftest.py             # Pytest fixtures
│   ├── agents/
│   │   ├── test_ocr_parser.py
│   │   ├── test_cost_extractor.py
│   │   └── ...
│   ├── integration/
│   │   ├── test_ingestion_flow.py
│   │   └── test_inference_flow.py
│   └── fixtures/
│       ├── sample_fda.pdf
│       └── mock_responses.json
└── .env.example                # Environment variables template
```

## Common Commands

| Command                                        | Purpose                              |
| :--------------------------------------------- | :----------------------------------- |
| `uv sync`                                      | Install dependencies (initial setup) |
| `uv sync --upgrade`                            | Update all dependencies to latest    |
| `uv add <package>`                             | Add a new dependency                 |
| `uv add --dev <package>`                       | Add a development dependency         |
| `uv run pytest`                                | Run tests                            |
| `uv run pytest -v -s`                          | Run tests with verbose output        |
| `uv run black src/ tests/`                     | Format code                          |
| `uv run ruff check src/`                       | Lint code                            |
| `uv run mypy src/`                             | Type check                           |
| `uv run pytest --cov=src --cov-report=html`    | Coverage report                      |
| `uv run streamlit run src/pda_intel/ui/app.py` | Run UI                               |

## Development Workflow

### Initial Setup

```bash
# Clone repo
git clone <repo-url>
cd pda_intel

# Install dependencies
uv sync --dev

# Install pre-commit hooks
uv run pre-commit install
```

### While Developing

```bash
# Make changes in src/

# Run tests (auto-formatted via pre-commit)
uv run pytest tests/ -v

# Add a new package dependency
uv add package-name

# Update lock file
uv lock --upgrade

# Commit changes
git add pyproject.toml uv.lock
git commit -m "Add new dependency"
```

### Before Pushing

```bash
# Format code
uv run black src/ tests/

# Lint
uv run ruff check src/ --fix

# Type check
uv run mypy src/

# Run full test suite
uv run pytest tests/ --cov=src
```

## Environment Variables

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Example `.env`:

```env
# Firebase
FIREBASE_PROJECT_ID=my-project
FIREBASE_CREDENTIALS_PATH=/path/to/credentials.json

# Google Cloud
GCP_PROJECT_ID=my-project
GCS_BUCKET=my-bucket
VERTEX_REGION=us-central1

# Gemini API
GEMINI_API_KEY=sk-...

# Tariff updates
TARIFF_UPDATE_EMAIL=admin@shippingagent.com
```

## Testing

### Run all tests

```bash
uv run pytest tests/ -v
```

### Run only unit tests (fast)

```bash
uv run pytest tests/ -m unit -v
```

### Run only integration tests

```bash
uv run pytest tests/ -m integration -v
```

### Run with coverage

```bash
uv run pytest tests/ --cov=src --cov-report=html
open htmlcov/index.html
```

### Run specific test file

```bash
uv run pytest tests/agents/test_ocr_parser.py -v
```

## Troubleshooting

| Issue                        | Solution                                          |
| :--------------------------- | :------------------------------------------------ |
| `uv: command not found`      | Install UV: `brew install uv` or `pip install uv` |
| Dependencies not installing  | Run `uv sync --upgrade`                           |
| Python 3.11 not found        | Install Python 3.11: `brew install python@3.11`   |
| Tests failing after git pull | Run `uv sync` to update dependencies              |
| Pre-commit hooks failing     | Run `uv run pre-commit autoupdate`                |

## Deployment

### Docker (Cloud Run)

```bash
docker build -t pda-intel .
docker run -p 8000:8000 pda-intel
```

### Cloud Functions

UV is automatically used in `requirements.txt` via PEP 621 export.

## References

- [UV Documentation](https://docs.astral.sh/uv/)
- [Pyproject.toml Spec](https://packaging.python.org/specifications/pyproject-toml/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Google Generative AI SDK](https://ai.google.dev/docs)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
