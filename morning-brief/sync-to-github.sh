#!/bin/bash
# Auto-sync Morning Brief to GitHub every 60 minutes

cd /home/nik/.openclaw/workspace/morning-brief

# Check if there are any changes
if [[ -n $(git status --porcelain) ]]; then
  echo "$(date): Changes detected, committing and pushing..."
  git add -A
  git commit -m "Auto-sync: $(date -u +%Y-%m-%d-%H:%M)"
  git push origin main
  echo "$(date): Push complete"
else
  echo "$(date): No changes to sync"
fi

# Always pull latest changes from remote to stay in sync
git pull origin main --rebase 2>/dev/null || true
