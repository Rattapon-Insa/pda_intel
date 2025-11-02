#!/bin/bash

echo "�� PDA Intel UV Setup Verification"
echo "=================================="
echo ""

# Check 1: UV
echo "1️⃣  UV Installation:"
if command -v uv &> /dev/null; then
    echo "✅ UV is installed: $(uv --version)"
else
    echo "❌ UV is NOT installed"
    exit 1
fi

# Check 2: Python Version
echo ""
echo "2️⃣  Python Version:"
PYTHON_VERSION=$(uv run python --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "✅ Python $PYTHON_VERSION"

# Check 3: Key Dependencies
echo ""
echo "3️⃣  Key Packages:"
uv run python -c "
import firebase_admin
import google.generativeai
import pydantic
import pandas
import pytest
print('✅ firebase-admin')
print('✅ google-generativeai')
print('✅ pydantic')
print('✅ pandas')
print('✅ pytest')
" 2>/dev/null || echo "❌ Some packages missing"

# Check 4: File Structure
echo ""
echo "4️⃣  Project Structure:"
for dir in src/pda_intel/agents src/pda_intel/schemas src/pda_intel/services tests; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/"
    else
        echo "❌ $dir/ NOT FOUND"
    fi
done

# Check 5: Configuration Files
echo ""
echo "5️⃣  Configuration Files:"
for file in pyproject.toml uv.lock .python-version .gitignore Dockerfile; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file NOT FOUND"
    fi
done

# Check 6: Documentation
echo ""
echo "6️⃣  Documentation:"
for doc in README.md SETUP_COMPLETE.md FIRST_AGENT_GUIDE.md 00_START_HERE.md; do
    if [ -f "$doc" ]; then
        echo "✅ $doc"
    else
        echo "❌ $doc NOT FOUND"
    fi
done

# Check 7: Virtual Environment
echo ""
echo "7️⃣  Virtual Environment:"
if [ -d ".venv" ]; then
    echo "✅ .venv/ exists"
else
    echo "⚠️  .venv/ not found (will be created on first uv run)"
fi

echo ""
echo "=================================="
echo "✅ Setup verification complete!"
echo ""
echo "Next: Read 00_START_HERE.md"
