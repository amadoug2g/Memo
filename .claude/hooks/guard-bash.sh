#!/bin/sh
# PreToolUse guard for agent Bash commands.
# Second line of defence behind the deny list in settings.json:
# blocks pushes to main, force pushes and history rewrites, even when
# they are chained or phrased in a way the deny patterns miss.
# Exit code 2 blocks the command and returns the message to the agent.

input=$(cat)

block() {
  echo "Blocked by .claude/hooks/guard-bash.sh: $1" >&2
  exit 2
}

case "$input" in
  *"git push"*"--force"*|*"git push"*" -f"*|*"git push"*"+"*)
    block "force push is not allowed. Open a pull request instead." ;;
  *"git push"*" main"*|*"git push"*":main"*|*"git push"*"HEAD:main"*)
    block "direct push to main is not allowed. Push a feature/* branch and open a pull request." ;;
  *"git reset --hard"*|*"git rebase"*"main"*|*"filter-branch"*)
    block "history rewrites need a human." ;;
  *"--no-verify"*)
    block "skipping hooks is not allowed." ;;
esac

exit 0
