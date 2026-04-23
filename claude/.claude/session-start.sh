#!/usr/bin/env bash
#if git remote get-url origin 2>/dev/null | grep -qi "synvolution"; then
#  f="$HOME/Nextcloud-syn/Shared/AI/Start.md"
#else
#  f="$HOME/Nextcloud/secondbrain/CLAUDE.md"
#fi
#if [ -f "$f" ]; then
#  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}' "$(jq -Rs . < "$f")"
#fi

set -e

AI_ROOT="$HOME/Nextcloud-syn/Shared/AI"
DEFAULT_AI_STARTPOINT="$HOME/Nextcloud/secondbrain/CLAUDE.md"

REPO_URL=""
if [ -d ".git" ]; then
  REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
fi

# Token optimization warnings
WARNINGS=""
if ! grep -q 'context-mode' ~/.claude/settings.json 2>/dev/null; then
  WARNINGS="$WARNINGS\n- context-mode plugin not enabled in ~/.claude/settings.json"
fi

if [[ "$REPO_URL" == *"github.com/Synvolution"* ]]; then
  PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)

  CONTEXT="AURA_PROJECT=$PROJECT
AURA_ROOT=$AI_ROOT

---

$(cat "$AI_ROOT/Start.md" 2>/dev/null || true)

---

$(cat "$AI_ROOT/Rules.md" 2>/dev/null || true)"

else
  AI_ROOT=$(dirname "$DEFAULT_AI_STARTPOINT")
  CONTEXT="AURA_ROOT=$AI_ROOT

$(cat "$DEFAULT_AI_STARTPOINT" 2>/dev/null)"
fi

STATUS_MSG="Context geladen"
if [ -n "$WARNINGS" ]; then
  STATUS_MSG="$STATUS_MSG\n\n⚠️ Token optimalisatie:$WARNINGS"
fi

printf '{"systemMessage": %s, "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": %s}}' \
  "$(printf '%s' "$STATUS_MSG" | jq -Rs .)" \
  "$(printf '%s' "$CONTEXT" | jq -Rs .)"