#!/usr/bin/env bash
set -euo pipefail

# ─── 경로 설정 ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
TEMPLATES_DIR="$ROOT/templates"
POLICIES_DIR="$ROOT/policies"
PROMPT_DIR="$ROOT/prompt"
MAILER_DIR="$ROOT/mailer"

# ─── .env 로드 ─────────────────────────────────────────────────
ENV_FILE="$ROOT/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Place your .env in project root." >&2
  exit 1
fi
set -o allexport
source "$ENV_FILE"
set +o allexport

# ─── 디버그: 환경변수 확인 ───────────────────────────────────────
echo "Loaded environment from $ENV_FILE:"
echo "  ACCOUNT_ID    = $ACCOUNT_ID"
echo "  AWS_REGION    = $AWS_REGION"
echo "  LAMBDA_ROLE   = $LAMBDA_ROLE"
echo "  MAILER_ROLE   = $MAILER_ROLE"
echo "  SLACK_WEBHOOK = $SLACK_WEBHOOK"
echo "  QUEUE_URL     = $QUEUE_URL"
echo

# ─── 1) prompt & mailer 생성 ────────────────────────────────────
mkdir -p "$PROMPT_DIR" "$MAILER_DIR"
echo "▶ Generating prompt/prompt.yaml"
envsubst < "$TEMPLATES_DIR/prompt.yaml.template" > "$PROMPT_DIR/prompt.yaml"
echo "▶ Generating mailer/mailer.yaml"
envsubst < "$TEMPLATES_DIR/mailer.yaml.template" > "$MAILER_DIR/mailer.yaml"
echo

# ─── 2) 사용자 입력 받기 ────────────────────────────────────────
read -p "Enter resources to process (e.g. ec2 elbv2) or all: " -a selection

# ─── 3) 템플릿 폴더 하위 리소스 목록 수집 ────────────────────────
all_resources=()
for d in "$TEMPLATES_DIR"/*/; do
  [ -d "$d" ] || continue
  all_resources+=("$(basename "$d")")
done

# ─── 4) 처리할 리소스 결정 ───────────────────────────────────────
if [ "${selection[0]}" = "all" ]; then
  to_process=("${all_resources[@]}")
else
  to_process=()
  for res in "${selection[@]}"; do
    if printf '%s\n' "${all_resources[@]}" | grep -qx "$res"; then
      to_process+=("$res")
    else
      echo "Warning: resource '$res' not found in templates/, skipping" >&2
    fi
  done
fi

# ─── 5) 정책 파일 생성 ─────────────────────────────────────────
for res in "${to_process[@]}"; do
  SRC="$TEMPLATES_DIR/$res"
  DST="$POLICIES_DIR/$res"
  mkdir -p "$DST"
  echo "▶ Processing resource: $res"
  for tpl in "$SRC"/*.yaml.template; do
    [ -f "$tpl" ] || continue
    OUT="$DST/$(basename "$tpl" .yaml.template).yaml"
    echo "  - Generating $OUT"
    envsubst < "$tpl" > "$OUT"
  done
done

echo
echo "🎉 Generation completed."
