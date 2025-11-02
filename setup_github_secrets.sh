#!/bin/bash

echo "🔧 Setting up GitHub Secrets for CI/CD"
echo "======================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install it with: brew install gh"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo "❌ Not logged in to GitHub"
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is ready"
echo ""

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)

if [ -z "$REPO" ]; then
    echo "❌ Not in a GitHub repository"
    echo "Initialize git and push to GitHub first:"
    echo "  git init"
    echo "  gh repo create"
    exit 1
fi

echo "📦 Repository: $REPO"
echo ""

# Load environment variables
if [ ! -f .env ]; then
    echo "❌ .env file not found"
    exit 1
fi

source .env

echo "🔐 Setting GitHub Secrets..."
echo ""

# Set secrets
gh secret set FIREBASE_PROJECT_ID --body "$FIREBASE_PROJECT_ID"
echo "✅ FIREBASE_PROJECT_ID"

gh secret set GCP_PROJECT_ID --body "$GCP_PROJECT_ID"
echo "✅ GCP_PROJECT_ID"

gh secret set GCS_BUCKET --body "$GCS_BUCKET"
echo "✅ GCS_BUCKET"

gh secret set GEMINI_API_KEY --body "$GEMINI_API_KEY"
echo "✅ GEMINI_API_KEY"

gh secret set VERTEX_REGION --body "$VERTEX_REGION"
echo "✅ VERTEX_REGION"

gh secret set GEMINI_MODEL_FLASH --body "$GEMINI_MODEL_FLASH"
echo "✅ GEMINI_MODEL_FLASH"

gh secret set GEMINI_MODEL_PRO --body "$GEMINI_MODEL_PRO"
echo "✅ GEMINI_MODEL_PRO"

echo ""
echo "======================================="
echo "✅ GitHub Secrets configured!"
echo ""
echo "📋 Next steps:"
echo "1. Push your code: git push origin main"
echo "2. Check workflows: gh workflow list"
echo "3. View runs: gh run list"
echo ""
echo "🔍 View secrets: gh secret list"
