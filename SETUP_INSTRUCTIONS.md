# Initial project structure setup

Now let's create the base directory structure and initial files:

## Step 1: Create source directory structure

```bash
cd /Users/rattapon.ins/side-project/pda_intel

# Create main source directories
mkdir -p src/pda_intel/agents/ingestion src/pda_intel/agents/inference src/pda_intel/agents/orchestrators
mkdir -p src/pda_intel/schemas src/pda_intel/services src/pda_intel/ui src/pda_intel/utils

# Create test directories
mkdir -p tests/agents/ingestion tests/agents/inference tests/integration tests/fixtures

# Create credentials directory (for local development)
mkdir -p credentials
echo "*.json" > credentials/.gitignore
```

## Step 2: Initialize UV and install dependencies

```bash
# Sync dependencies (this will create .venv and install all packages)
uv sync --dev

# Verify installation
uv run python --version
uv run pip list | head -20
```

## Step 3: Initialize git (if not already done)

```bash
git init
touch .gitignore
```

### Recommended .gitignore entries:

```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
.venv/
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Environment
.env
.env.local
.env.*.local

# Credentials
credentials/*.json
!credentials/.gitignore

# Test coverage
htmlcov/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Lock file (optional: commit to version control)
# uv.lock

# Logs
*.log

# Firebase
.firebaserc
```

## Step 4: Create initial **init**.py files

```python
# src/pda_intel/__init__.py
__version__ = "0.1.0"
__author__ = "Shipping Agent Team"

# src/pda_intel/agents/__init__.py
# Empty or with agent imports

# src/pda_intel/schemas/__init__.py
# Empty or with schema imports

# src/pda_intel/services/__init__.py
# Empty or with service imports

# src/pda_intel/utils/__init__.py
# Empty or with utility imports

# tests/__init__.py
# Empty

# tests/conftest.py
# Pytest configuration (see below)
```

## Step 5: Create conftest.py for test fixtures

```python
# tests/conftest.py
import pytest
import os
from pathlib import Path
from unittest.mock import MagicMock

# Add src to path
TESTS_DIR = Path(__file__).parent
PROJECT_ROOT = TESTS_DIR.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

@pytest.fixture
def mock_firestore():
    """Mock Firestore client for testing."""
    return MagicMock()

@pytest.fixture
def mock_gcs():
    """Mock GCS client for testing."""
    return MagicMock()

@pytest.fixture
def sample_fda_spec():
    """Sample FDA specification for testing."""
    return {
        "port": "Map Ta Phut",
        "is_shifting": True,
        "grt": 4626,
        "loa": 112,
        "draft": 6.5,
        "vessel_name": "MT. DING HENG 30",
        "voyage": "2518",
    }

@pytest.fixture
def sample_quotation_spec():
    """Sample quotation input for testing."""
    return {
        "port": "Map Ta Phut",
        "is_shifting": False,
        "grt": 4600,
        "loa": 112,
        "vessel_type": "Chemical Tanker",
    }
```

## Step 6: Verify setup

```bash
# Check that UV is working
uv --version

# Verify Python environment
uv run python --version

# List installed packages
uv run pip list

# Run a test (should be empty initially)
uv run pytest tests/ -v

# Format code
uv run black src/ tests/

# Lint
uv run ruff check src/

# Type check
uv run mypy src/
```

## ✅ UV Setup Complete!

You now have:

- ✅ `pyproject.toml` - Project metadata + dependencies
- ✅ `uv.lock` - Locked versions (auto-generated after first sync)
- ✅ `.python-version` - Python 3.11.5
- ✅ `.env.example` - Environment variables template
- ✅ `.pre-commit-config.yaml` - Pre-commit hooks
- ✅ `Dockerfile` - Container setup
- ✅ `README.md` - Quick start guide
- ✅ Directory structure for agents, schemas, services, etc.
- ✅ Pytest configuration + fixtures

## Next Steps

1. **Create the first agent**: Start with `condition_tagger_agent` (simplest)
2. **Write unit tests**: Create `tests/agents/test_condition_tagger.py`
3. **Implement agent**: Fill in `src/pda_intel/agents/ingestion/condition_tagger.py`
4. **Run tests**: `uv run pytest tests/agents/test_condition_tagger.py -v`
5. **Repeat** for each agent in dependency order

Ready to build! 🚀
