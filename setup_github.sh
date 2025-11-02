#!/bin/bash

# GitHub Repository Setup Script
# This script helps you set up the GitHub repository with CI/CD

echo "🚀 GitHub Repository Setup for PDA Intel"
echo "========================================"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "   Install with: brew install gh"
    exit 1
fi

echo "✅ GitHub CLI detected: $(gh --version | head -1)"
echo ""

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "⚠️  Not authenticated with GitHub"
    echo "   Run: gh auth login"
    exit 1
fi

echo "✅ GitHub authenticated"
echo ""

# Ask for repository name
read -p "Enter GitHub repository name (e.g., myorg/pda-intel): " REPO_NAME

if [ -z "$REPO_NAME" ]; then
    echo "❌ Repository name cannot be empty"
    exit 1
fi

echo ""
echo "Creating GitHub repository: $REPO_NAME"
echo ""

# Create repository (public or private)
read -p "Make repository private? (y/n): " IS_PRIVATE

if [ "$IS_PRIVATE" = "y" ]; then
    gh repo create "$REPO_NAME" --private --source=. --remote=origin --push || {
        echo "⚠️  Repository might already exist. Trying to add remote..."
        git remote add origin "https://github.com/$REPO_NAME.git" 2>/dev/null || true
    }
else
    gh repo create "$REPO_NAME" --public --source=. --remote=origin --push || {
        echo "⚠️  Repository might already exist. Trying to add remote..."
        git remote add origin "https://github.com/$REPO_NAME.git" 2>/dev/null || true
    }
fi

echo ""
echo "✅ Repository created/connected"
echo ""

# Configure secrets
echo "📝 Now let's configure GitHub Secrets for CI/CD"
echo ""
echo "You'll need the following secrets:"
echo "  - FIREBASE_PROJECT_ID"
echo "  - FIREBASE_CREDENTIALS (base64 encoded)"
echo "  - GCP_PROJECT_ID"
echo "  - GCS_BUCKET"
echo "  - GEMINI_API_KEY"
echo "  - VERTEX_REGION"
echo "  - VERTEX_MATCHING_INDEX_ID"
echo "  - VERTEX_MATCHING_ENDPOINT_ID"
echo ""

read -p "Do you want to set secrets now? (y/n): " SET_SECRETS

if [ "$SET_SECRETS" = "y" ]; then
    echo ""
    read -p "FIREBASE_PROJECT_ID: " FIREBASE_PROJECT_ID
    [ -n "$FIREBASE_PROJECT_ID" ] && gh secret set FIREBASE_PROJECT_ID --body "$FIREBASE_PROJECT_ID"

    read -p "GCP_PROJECT_ID: " GCP_PROJECT_ID
    [ -n "$GCP_PROJECT_ID" ] && gh secret set GCP_PROJECT_ID --body "$GCP_PROJECT_ID"

    read -p "GCS_BUCKET: " GCS_BUCKET
    [ -n "$GCS_BUCKET" ] && gh secret set GCS_BUCKET --body "$GCS_BUCKET"

    read -p "GEMINI_API_KEY: " GEMINI_API_KEY
    [ -n "$GEMINI_API_KEY" ] && gh secret set GEMINI_API_KEY --body "$GEMINI_API_KEY"

    read -p "VERTEX_REGION (default: us-central1): " VERTEX_REGION
    VERTEX_REGION=${VERTEX_REGION:-us-central1}
    gh secret set VERTEX_REGION --body "$VERTEX_REGION"

    echo ""
    read -p "Path to Firebase credentials JSON: " FIREBASE_CREDS_PATH
    if [ -f "$FIREBASE_CREDS_PATH" ]; then
        FIREBASE_CREDS_BASE64=$(cat "$FIREBASE_CREDS_PATH" | base64)
        gh secret set FIREBASE_CREDENTIALS --body "$FIREBASE_CREDS_BASE64"
        echo "✅ Firebase credentials uploaded"
    else
        echo "⚠️  File not found: $FIREBASE_CREDS_PATH (you can set this later)"
    fi

    echo ""
    echo "✅ Secrets configured"
else
    echo "⚠️  You can set secrets later using:"
    echo "   gh secret set SECRET_NAME --body \"SECRET_VALUE\""
    echo "   Or via GitHub web UI: Settings → Secrets and variables → Actions"
fi

echo ""
echo "========================================"
echo "✅ GitHub setup complete!"
echo ""
echo "Next steps:"
echo "  1. View your repository: gh repo view --web"
echo "  2. Check workflows: gh workflow list"
echo "  3. View CI/CD guide: cat CI_CD_GUIDE.md"
echo ""
echo "To push code:"
echo "  git add ."
echo "  git commit -m \"Initial commit\""
echo "  git push -u origin main"
echo ""
