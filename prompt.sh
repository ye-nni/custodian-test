#!/usr/bin/env bash
set -euo pipefail

REGION="ap-northeast-2"
OUTDIR="./out"
PROMPT_FILE="prompt/prompt.yaml"
MAILER_FILE="mailer/mailer.yaml"

usage() {
  cat <<EOF
Usage: $(basename "$0") <policy-keyword> [<policy-keyword>...]

  policy-keyword  : substring to match policy names, or 'all' to run every policy

Examples:
  # run every policy in prompt.yaml
  $(basename "$0") all

  # run just one
  $(basename "$0") ec2_ebs_volume_snapshots_exists

  # run multiple
  $(basename "$0") ec2_ebs elbv2_deletion
EOF
  exit 1
}

[ $# -ge 1 ] || usage
mkdir -p "$OUTDIR"

# special case: all
if [ "$1" = "all" ]; then
  echo "▶ Running ALL policies in $PROMPT_FILE"
  if custodian run --region "$REGION" -s "$OUTDIR" "$PROMPT_FILE"; then
    echo "🎉 All policies have been executed successfully!"
    exit 0
  else
    echo "❌ Failed to execute all policies."
    exit 1
  fi
fi

# otherwise treat each argument as a substring match
errors=()
for keyword in "$@"; do
  echo "▶ Running policies matching '$keyword' in $PROMPT_FILE"
  if custodian run \
       --region "$REGION" \
       -s "$OUTDIR" \
       -p "$keyword" \
       "$PROMPT_FILE"; then
    echo "✅ Policy filter '$keyword' succeeded"
  else
    echo "❌ Policy filter '$keyword' failed"
    errors+=("$keyword")
  fi
  echo
done

if [ ${#errors[@]} -gt 0 ]; then
  echo "⚠️ Errors for filters: ${errors[*]}"
  exit 2
else
  echo "🎉 All specified policies have been executed successfully!"
  fi

# Ask to run mailer
echo
read -p "Would you like to run the mailer (c7n-mailer)? [y/N]: " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  echo "▶ Running c7n-mailer with $MAILER_FILE"
  c7n-mailer -c "./$MAILER_FILE" --run
  echo "✅ Mailer executed."
else
  echo "▶ Skipping mailer."
fi

exit 0
