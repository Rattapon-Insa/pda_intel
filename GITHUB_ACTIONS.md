# 🚀 CI/CD with GitHub Actions

## Quick Setup

```bash
# 1. Make sure you have gh CLI
gh --version

# 2. Login to GitHub
gh auth login

# 3. Create GitHub repo (if not exists)
gh repo create pda_intel --public --source=. --remote=origin

# 4. Setup GitHub secrets
./setup_github_secrets.sh

# 5. Push code
git add .
git commit -m "Initial commit with CI/CD"
git push origin main
```

## 📋 Workflows

| Workflow | Trigger | Purpose |
| :--- | :--- | :--- |
| **Test & Lint** | Push/PR | Run tests, lint, type check |
| **Code Quality** | Push/PR | Quality metrics, complexity |
| **Integration** | Push/Schedule | Integration & sandbox tests |
| **Update Deps** | Weekly/Manual | Update dependencies via PR |

## 🔐 Required Secrets

Run `./setup_github_secrets.sh` to configure:

- `FIREBASE_PROJECT_ID` = `pda-controller-446305`
- `GCP_PROJECT_ID` = `pda-controller-446305`
- `GCS_BUCKET` = `pda-intel-storage`
- `GEMINI_API_KEY` = (from `.env`)
- `VERTEX_REGION` = `asia-southeast1`
- `GEMINI_MODEL_FLASH` = `gemini-2.5-flash-preview-09-2025`
- `GEMINI_MODEL_PRO` = `gemini-2.5-pro`

Verify: `gh secret list`

## 🧪 Local Testing (Before Push)

```bash
# Run all checks
uv run pytest tests/ -v
uv run black src/ tests/ --check
uv run ruff check src/ tests/
uv run mypy src/ --ignore-missing-imports
```

## 🔄 Development Workflow

```bash
# 1. Create feature branch
git checkout -b agent/condition-tagger

# 2. Develop (TDD)
# Write tests → Implement → Test locally

# 3. Push & create PR
git add .
git commit -m "Add condition_tagger_agent"
git push origin agent/condition-tagger
gh pr create --fill

# 4. CI runs automatically
# 5. Merge after approval
gh pr merge --squash
```

## 📊 Monitor Workflows

```bash
gh workflow list        # List workflows
gh run list             # View recent runs
gh run view             # View latest run
gh run view --log       # View logs
gh run watch            # Watch live
```

## 🐛 Debug Failed Workflow

```bash
gh run view --log                 # Check logs
gh run rerun --failed             # Re-run
uv run pytest tests/ -v           # Test locally
```

## ✅ Setup Complete When

- [ ] GitHub repo created
- [ ] Secrets configured
- [ ] First commit pushed
- [ ] Workflows passing ✅

View: `https://github.com/YOUR_ORG/pda_intel/actions`
