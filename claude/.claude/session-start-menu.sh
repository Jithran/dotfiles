#!/usr/bin/env bash
set -e

# Token optimization warnings
WARNINGS=""
if ! grep -q 'context-mode' ~/.claude/settings.json 2>/dev/null; then
  WARNINGS="$WARNINGS\n- context-mode plugin not enabled in ~/.claude/settings.json"
fi
if ! grep -q '"autoMemoryEnabled": false' ~/.claude/settings.json 2>/dev/null; then
  WARNINGS="$WARNINGS\n- ⚠ autoMemoryEnabled staat aan — AI-OS is de enige bron van waarheid. Voeg \"autoMemoryEnabled\": false toe aan ~/.claude/settings.json"
fi

CONTEXT="Beschikbare second brains (keuze volgt via CLAUDE.md):
1. ~/Nextcloud/secondbrain - Sonny (privé)
2. ~/Nextcloud-syn/Shared/AI/Start.md - Aura (zakelijk)"

STATUS_MSG=$'Welke second brain wil je laden?\n  1. Sonny (privé)\n  2. Aura (zakelijk)'
if [ -n "$WARNINGS" ]; then
  STATUS_MSG="$STATUS_MSG\n\n⚠ Token optimalisatie:$WARNINGS"
fi

printf '{"systemMessage": %s, "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": %s}}' \
  "$(printf '%s' "$STATUS_MSG" | jq -Rs .)" \
  "$(printf '%s' "$CONTEXT" | jq -Rs .)"
