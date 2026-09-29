#!/usr/bin/env bash
# Tests d'isolation pour un compte client.
#
#   ./check_isolation.sh --client cla --user clienta_test --other clb [--other clc]
#
# 1. le compte lit son propre index           -> HTTP 200 attendu
# 2. le compte ne lit pas l'index d'un autre  -> HTTP 403 attendu
# 3. recherche sur wazuh-alerts-* (dashboard) -> seul son code client doit apparaître
#
# Variables : INDEXER_URL (défaut https://localhost:9200), INDEXER_CA (sinon -k).
set -uo pipefail

INDEXER_URL=${INDEXER_URL:-https://localhost:9200}
CURL_TLS=(-k)
[[ -n ${INDEXER_CA:-} ]] && CURL_TLS=(--cacert "$INDEXER_CA")

CODE="" USER_NAME="" OTHERS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --client) CODE=$2; shift 2 ;;
    --user)   USER_NAME=$2; shift 2 ;;
    --other)  OTHERS+=("$2"); shift 2 ;;
    *) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
  esac
done
[[ -n $CODE && -n $USER_NAME ]] || { echo "--client et --user sont obligatoires"; exit 1; }

read -r -s -p "Mot de passe de $USER_NAME : " PW; echo
PASS=0 FAIL=0
pass() { printf '\033[1;32mPASS\033[0m %s\n' "$*"; PASS=$((PASS+1)); }
fail() { printf '\033[1;31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*"; }

BODY=$(mktemp); trap 'rm -f "$BODY"' EXIT
req() {  # req <méthode> <chemin> [json] -> écrit le corps dans $BODY, renvoie le code HTTP
  local args=(-s "${CURL_TLS[@]}" -u "$USER_NAME:$PW" -o "$BODY" -w '%{http_code}' -X "$1" "$INDEXER_URL/$2")
  [[ -n ${3:-} ]] && args+=(-H 'Content-Type: application/json' -d "$3")
  curl "${args[@]}"
}

# Test 1 — propre index
code=$(req GET "wazuh-alerts-4.x-$CODE-*/_count")
if [[ $code == 200 ]]; then
  n=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["count"])' "$BODY")
  pass "1. lecture de wazuh-alerts-4.x-$CODE-* : $n documents"
  [[ $n -gt 0 ]] || warn "   index vide : générer une alerte chez ce client pour un test probant"
else
  fail "1. lecture de son propre index : HTTP $code (attendu 200)"
fi

# Test 2 — index des autres clients
for other in "${OTHERS[@]}"; do
  code=$(req GET "wazuh-alerts-4.x-$other-*/_count")
  if [[ $code == 403 ]]; then
    pass "2. accès refusé à wazuh-alerts-4.x-$other-* (403)"
  else
    fail "2. accès à wazuh-alerts-4.x-$other-* : HTTP $code (attendu 403)"
  fi
done

# Test 3 — motif global utilisé par le dashboard
code=$(req POST "wazuh-alerts-*/_search?size=0" \
  '{"aggs":{"clients":{"terms":{"field":"agent.labels.client","size":50}}}}')
if [[ $code == 403 ]]; then
  warn "3. wazuh-alerts-* refusé (403) : pas de fuite, mais do_not_fail_on_forbidden n'est pas actif (dashboard inutilisable)"
elif [[ $code == 200 ]]; then
  keys=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(" ".join(b["key"] for b in d["aggregations"]["clients"]["buckets"]))' "$BODY")
  if [[ -z $keys || $keys == "$CODE" ]]; then
    pass "3. wazuh-alerts-* ne renvoie que le client '$CODE'"
  else
    fail "3. wazuh-alerts-* renvoie d'autres clients : $keys"
  fi
else
  fail "3. wazuh-alerts-* : HTTP $code"
fi

echo "---"
echo "Résultat : $PASS réussi(s), $FAIL échec(s)"
[[ $FAIL -eq 0 ]]
