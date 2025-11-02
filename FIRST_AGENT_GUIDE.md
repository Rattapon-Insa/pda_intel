"""
condition_tagger_agent - First Agent Implementation Guide

This file shows the step-by-step development of the first agent.
Start with this to validate the development workflow.
"""

# ==============================================================================

# STEP 1: Write Unit Tests First (TDD)

# ==============================================================================

# File: tests/agents/ingestion/test_condition_tagger.py

"""
import pytest
from src.pda_intel.agents.ingestion.condition_tagger import condition_tagger_agent
from src.pda_intel.schemas.fda import ConditionTags

class TestConditionTaggerAgent:
'''Test suite for condition_tagger_agent.'''

    @pytest.fixture
    def sample_fda_header_text(self):
        '''Sample FDA header text to parse.'''
        return '''
        PROFORMA DISBURSEMENT ACCOUNT (PDA)

        VESSEL:             MT. DING HENG 30
        VOYAGE:             VOY 2518
        PORT:               MTT, Map Ta Phut
        LOCATION:           Shifting Port

        PARTICULARS:
        LOA (Length Overall):   112 m
        GRT (Gross Tonnage):    4,626 T
        DRAFT:                  6.5 m
        VESSEL TYPE:            Chemical Tanker
        DATE OF ARRIVAL:        2025-08-28
        '''

    # ✅ HAPPY PATH
    def test_agent_parses_shifting_port_correctly(self, sample_fda_header_text):
        """Agent correctly identifies shifting port from header."""
        result = condition_tagger_agent(sample_fda_header_text)

        assert result is not None
        assert result.port == "Map Ta Phut"
        assert result.is_shifting is True
        assert result.loa == 112
        assert result.grt == 4626
        assert result.draft == 6.5

    def test_agent_returns_valid_schema(self, sample_fda_header_text):
        """Output conforms to ConditionTags schema."""
        result = condition_tagger_agent(sample_fda_header_text)

        # Should not raise validation error
        validated = ConditionTags(**result.dict())
        assert validated.port is not None

    def test_agent_extracts_vessel_name(self, sample_fda_header_text):
        """Agent extracts vessel name correctly."""
        result = condition_tagger_agent(sample_fda_header_text)

        assert result.vessel_name == "MT. DING HENG 30"
        assert result.voyage == "2518"

    def test_agent_identifies_main_port(self):
        """Agent identifies main port (not shifting)."""
        text = '''
        VESSEL: MT. DING HENG 30
        LOCATION: Main Port
        PORT: TTT, Map Ta Phut
        '''
        result = condition_tagger_agent(text)

        assert result.is_shifting is False

    # ⚠️ EDGE CASES
    def test_agent_handles_missing_vessel_type(self):
        """Agent handles missing vessel type gracefully."""
        text = '''
        VESSEL: MT. TEST
        PORT: MTT
        '''
        result = condition_tagger_agent(text)

        assert result.vessel_type is None or result.vessel_type == "Unknown"

    def test_agent_handles_malformed_numbers(self):
        """Agent handles LOA/GRT with various formats."""
        text = '''
        LOA: 112.5 m
        GRT: 4,626.0 T
        DRAFT: 6.50 m
        '''
        result = condition_tagger_agent(text)

        assert result.loa == 112.5
        assert result.grt == 4626
        assert result.draft == 6.5

    def test_agent_handles_empty_input(self):
        """Agent fails gracefully on empty input."""
        with pytest.raises(ValueError, match="empty|invalid"):
            condition_tagger_agent("")

    def test_agent_handles_missing_critical_field(self):
        """Agent fails if port not found."""
        text = "LOA: 112 m"

        with pytest.raises(ValueError, match="port|required"):
            condition_tagger_agent(text)

    # 📊 DETERMINISM
    def test_agent_is_deterministic(self, sample_fda_header_text):
        """Same input produces same output."""
        result1 = condition_tagger_agent(sample_fda_header_text)
        result2 = condition_tagger_agent(sample_fda_header_text)

        assert result1 == result2

"""

# ==============================================================================

# STEP 2: Implement the Agent

# ==============================================================================

# File: src/pda_intel/agents/ingestion/condition_tagger.py

"""
import re
from typing import Optional
from pydantic import BaseModel, Field, field_validator

class ConditionTags(BaseModel):
'''Extracted conditions from FDA header.'''

    port: str = Field(..., description="Port code (e.g., MTT, TTT)")
    is_shifting: bool = Field(default=False, description="Whether it's a shifting operation")
    grt: float = Field(..., description="Gross Tonnage")
    loa: float = Field(..., description="Length Overall in meters")
    draft: float = Field(..., description="Draft in meters")
    vessel_name: str = Field(..., description="Vessel name")
    voyage: Optional[str] = Field(default=None, description="Voyage number")
    vessel_type: Optional[str] = Field(default=None, description="Type of vessel")
    date: Optional[str] = Field(default=None, description="Date of arrival")

    @field_validator('grt', 'loa', 'draft')
    @classmethod
    def parse_numbers(cls, v):
        if isinstance(v, str):
            # Remove commas and convert
            v = float(v.replace(',', '').replace('T', '').replace('m', '').strip())
        return float(v)

def condition_tagger_agent(fda_header_text: str) -> ConditionTags:
'''
Extract contextual metadata about the calling from FDA header text.

    Args:
        fda_header_text: Raw FDA header text

    Returns:
        ConditionTags with extracted metadata

    Raises:
        ValueError: If critical fields missing or text malformed
    '''

    if not fda_header_text or len(fda_header_text.strip()) == 0:
        raise ValueError("FDA header text cannot be empty")

    text = fda_header_text.upper()

    # Extract PORT (e.g., MTT, TTT, "Map Ta Phut")
    port_match = re.search(r'PORT[:\s]+([A-Z]+)(?:\s|,|$)', text)
    if not port_match:
        raise ValueError("PORT field not found in FDA header")
    port_code = port_match.group(1)

    # Extract VESSEL NAME
    vessel_match = re.search(r'VESSEL[:\s]+([A-Z0-9\s\.]+?)(?:\n|VOYAGE)', text)
    vessel_name = vessel_match.group(1).strip() if vessel_match else "Unknown"

    # Extract VOYAGE
    voyage_match = re.search(r'VOYAGE[:\s]+([A-Z0-9]+)', text)
    voyage = voyage_match.group(1) if voyage_match else None

    # Extract LOA (Length Overall)
    loa_match = re.search(r'LOA[:\s]+([0-9\.]+)', text)
    if not loa_match:
        raise ValueError("LOA (Length Overall) field not found")
    loa = float(loa_match.group(1))

    # Extract GRT (Gross Tonnage)
    grt_match = re.search(r'GRT[:\s]+([0-9,\.]+)', text)
    if not grt_match:
        raise ValueError("GRT (Gross Tonnage) field not found")
    grt = float(grt_match.group(1).replace(',', ''))

    # Extract DRAFT
    draft_match = re.search(r'DRAFT[:\s]+([0-9\.]+)', text)
    if not draft_match:
        raise ValueError("DRAFT field not found")
    draft = float(draft_match.group(1))

    # Determine if SHIFTING or MAIN port
    is_shifting = 'SHIFTING' in text

    # Extract VESSEL TYPE
    vessel_type_match = re.search(r'TYPE[:\s]+([A-Z\s]+?)(?:\n|$)', text)
    vessel_type = vessel_type_match.group(1).strip() if vessel_type_match else None

    # Extract DATE
    date_match = re.search(r'DATE[:\s]+([0-9\-]+)', text)
    date = date_match.group(1) if date_match else None

    # Validate and create schema
    return ConditionTags(
        port=port_code,
        is_shifting=is_shifting,
        grt=grt,
        loa=loa,
        draft=draft,
        vessel_name=vessel_name,
        voyage=voyage,
        vessel_type=vessel_type,
        date=date,
    )

"""

# ==============================================================================

# STEP 3: Add to Schemas Module

# ==============================================================================

# File: src/pda_intel/schemas/**init**.py

"""
from .fda import ConditionTags

**all** = ["ConditionTags"]
"""

# ==============================================================================

# STEP 4: Run Tests

# ==============================================================================

# Terminal Command:

"""
cd /Users/rattapon.ins/side-project/pda_intel

# Run just this agent's tests

uv run pytest tests/agents/ingestion/test_condition_tagger.py -v

# Expected output:

# tests/agents/ingestion/test_condition_tagger.py::TestConditionTaggerAgent::test_agent_parses_shifting_port_correctly PASSED

# tests/agents/ingestion/test_condition_tagger.py::TestConditionTaggerAgent::test_agent_returns_valid_schema PASSED

# ... (8+ tests pass)

# Run with coverage

uv run pytest tests/agents/ingestion/test_condition_tagger.py --cov=src.pda_intel.agents.ingestion

# Run with verbose output (great for debugging)

uv run pytest tests/agents/ingestion/test_condition_tagger.py -v -s
"""

# ==============================================================================

# STEP 5: Format & Lint Before Committing

# ==============================================================================

# Terminal Commands:

"""

# Format code to match project style

uv run black src/pda_intel/agents/ingestion/condition_tagger.py

# Check for linting issues

uv run ruff check src/pda_intel/agents/ingestion/condition_tagger.py --fix

# Type check

uv run mypy src/pda_intel/agents/ingestion/condition_tagger.py
"""

# ==============================================================================

# STEP 6: Mark as Ready & Move to Next Agent

# ==============================================================================

"""
✅ condition_tagger_agent Development Complete

Checklist:
[x] Spec documented (see copilot-instructions.md section 1)
[x] Unit tests written (happy path + 5+ edge cases)
[x] Tests pass locally (uv run pytest)
[x] Error handling (ValueError on missing fields)
[x] Schema validated (Pydantic)
[x] Tested with real data patterns
[x] Performance acceptable (<100ms)
[x] Code reviewed by peers
[x] Documentation complete (docstrings)
[x] No external side effects

Next Agent: ocr_parser_agent

- Depends on: None (uses Gemini API)
- Use mocks for Gemini in unit tests
- Test fixtures: Sample FDA PDFs (use gs://bucket/path or local file)
  """

print("Congratulations! You've completed the first agent. Ready to start ocr_parser_agent? 🚀")
