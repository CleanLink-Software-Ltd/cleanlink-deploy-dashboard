#!/usr/bin/env bash
set -euo pipefail

REPOS=(
  "CleanLink-Software-Ltd/process-portal"
  "CleanLink-Software-Ltd/process-portal-image-v2"
  "CleanLink-Software-Ltd/aws-clean-link-usage"
  "CleanLink-Software-Ltd/aws-clean-link-summer"
  "CleanLink-Software-Ltd/aws-clean-link-stock-summer"
  "CleanLink-Software-Ltd/aws-clean-link-parser"
  "CleanLink-Software-Ltd/portal-api"
  "CleanLink-Software-Ltd/portal-api-infra"
  "CleanLink-Software-Ltd/pt"
  "CleanLink-Software-Ltd/ng-pt-v3"
)
ENVIRONMENTS=(dev prod)

results="[]"
for repo in "${REPOS[@]}"; do
  for env in "${ENVIRONMENTS[@]}"; do
    deployment=$(gh api "/repos/$repo/deployments?environment=$env&per_page=1" 2>/dev/null | jq '.[0] // empty')

    if [ -n "$deployment" ]; then
      id=$(echo "$deployment" | jq -r '.id')
      status=$(gh api "/repos/$repo/deployments/$id/statuses?per_page=1" --jq '.[0].state // "pending"' 2>/dev/null || echo "pending")
      entry=$(echo "$deployment" | jq \
        --arg env "$env" \
        --arg repo "$repo" \
        --arg status "$status" '{
          repo: $repo,
          environment: $env,
          sha: .sha,
          ref: .ref,
          created_at: .created_at,
          creator: .creator.login,
          status: $status
        }')
    else
      entry=$(jq -n --arg env "$env" --arg repo "$repo" '{
        repo: $repo,
        environment: $env,
        sha: null,
        ref: null,
        created_at: null,
        creator: null,
        status: "none"
      }')
    fi

    results=$(echo "$results" | jq ". + [$entry]")
  done
done

mkdir -p docs
jq -n \
  --argjson r "$results" \
  --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{updated_at: $t, deployments: $r}' > docs/data.json

echo "Wrote docs/data.json"
