"""Test fixtures and configuration."""
import sys
from pathlib import Path
from unittest.mock import MagicMock

import pytest

# Add src to path
TESTS_DIR = Path(__file__).parent
PROJECT_ROOT = TESTS_DIR.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))


@pytest.fixture
def mock_firestore():
    """Mock Firestore client for testing."""
    mock = MagicMock()
    mock.collection.return_value.document.return_value.get.return_value.to_dict.return_value = {}
    return mock


@pytest.fixture
def mock_gcs():
    """Mock GCS client for testing."""
    return MagicMock()


@pytest.fixture
def mock_vertex_ai():
    """Mock Vertex AI Matching Engine client for testing."""
    return MagicMock()


@pytest.fixture
def mock_gemini():
    """Mock Gemini API client for testing."""
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


@pytest.fixture
def sample_fda_breakdown():
    """Sample FDA cost breakdown for testing."""
    return {
        "port": "Map Ta Phut",
        "is_shifting": True,
        "vessel": "MT. DING HENG 30",
        "grt": 4626,
        "loa": 112,
        "draft": 6.5,
        "breakdown": {
            "tug_hire": 92876,
            "rope_boat": 5567,
            "pilotage": 12543,
            "clearance": 2000,
            "formality": 5440,
        },
        "total": 118426,
    }
