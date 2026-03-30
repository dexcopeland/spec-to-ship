#!/bin/bash

# ════════════════════════════════════════════════════════════════
#  Project Template Setup
#  Run once after cloning/copying this template to a new project.
#  Usage: ./setup.sh [project-name]
# ════════════════════════════════════════════════════════════════

PROJECT_NAME=${1:-"my-project"}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Spec-Driven Dev Template Setup          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Create required directories
echo "📁 Creating directories..."
mkdir -p docs
mkdir -p scripts/ralph
mkdir -p screenshots
mkdir -p .claude/commands
echo "   ✅ Directories created"

# 2. Make ralph executable
echo ""
echo "⚙️  Setting permissions..."
chmod +x scripts/ralph/ralph.sh
echo "   ✅ scripts/ralph/ralph.sh is executable"

# 3. Create .env.local from example if it doesn't exist
echo ""
echo "🔑 Environment file..."
if [ ! -f ".env.local" ]; then
  cp .env.example .env.local
  echo "   ✅ .env.local created from .env.example"
  echo "   ⚠️  Fill in your actual values in .env.local before running the build loop"
else
  echo "   ℹ️  .env.local already exists — skipping"
fi

# 4. Initialize git if not already initialized
echo ""
echo "🗂️  Git..."
if [ ! -d ".git" ]; then
  git init
  git add .
  git commit -m "chore: initialize project from spec-driven dev template"
  echo "   ✅ Git initialized with initial commit"
else
  echo "   ℹ️  Git already initialized — skipping"
fi

# 5. Update CLAUDE.md with project name
echo ""
echo "📝 Updating CLAUDE.md..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" CLAUDE.md
else
  sed -i "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" CLAUDE.md
fi
echo "   ✅ Project name set to: $PROJECT_NAME"

# 6. Check dependencies
echo ""
echo "🔍 Checking dependencies..."

command -v node >/dev/null 2>&1 && echo "   ✅ node: $(node --version)" || echo "   ❌ node: not found — install from nodejs.org"
command -v jq >/dev/null 2>&1 && echo "   ✅ jq: $(jq --version)" || echo "   ⚠️  jq: not found — install with: brew install jq"
command -v claude >/dev/null 2>&1 && echo "   ✅ claude: found" || echo "   ❌ claude: not found — install Claude Code CLI"
command -v git >/dev/null 2>&1 && echo "   ✅ git: $(git --version)" || echo "   ❌ git: not found"

# 7. Done
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Setup complete!                         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Next steps:"
echo ""
echo "  1. Open this folder in Claude Code:"
echo "     claude ."
echo ""
echo "  2. Run the discovery interview:"
echo "     /spec-discovery"
echo ""
echo "  3. Review docs/SPEC.md and make any edits"
echo ""
echo "  4. Generate the task list:"
echo "     /spec-to-prd"
echo ""
echo "  5. Verify your environment:"
echo "     /env-check"
echo ""
echo "  6. Start building:"
echo "     ./scripts/ralph/ralph.sh 20"
echo ""
