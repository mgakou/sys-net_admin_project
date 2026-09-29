#!/usr/bin/env bash
# Audit du routage des alertes (compte admin de l'indexer).
#
#   ./audit_routage.sh
#
# - liste les index wazuh-alerts-* par client ;
# - vérifie que chaque index client ne contient que son propre label ;
# - liste les agents présents dans « unassigned » (agents à affecter).
#
# Variables : INDEXER_URL (défaut https://localhost:9200), INDEXER_CA (sinon -k),
#             INDEXER_ADMIN_PW (sinon demandé).
set -uo pipefail

INDEXER_URL=${INDEXER_URL:-https://localhost:9200}
CURL_TLS=(-k)
[[ -n ${INDEXER_CA:-} ]] && CURL_TLS=(--cacert "$INDEXER_CA")
if [[ -z ${INDEXER_ADMIN_PW:-} ]]; then
  read -r -s -p "Mot de passe admin de l'indexer : " INDEXER_ADMIN_PW; echo
fi

q() { curl -s "${CURL_TLS[@]}" -u "admin:$INDEXER_ADMIN_PW" "$@"; }
agg() {  # agg <motif d'index> <champ>
  q -X POST "$INDEXER_URL/$1/_search?size=0" -H 'Content-Type: application/json' \
    -d "{\"aggs\":{\"a\":{\"terms\":{\"field\":\"$2\",\"size\":100}}}}" \
  | python3 -c 'import json,sys
d=json.load(sys.stdin)
if "error" in d: print("ERREUR:", d["error"].get("type")); sys.exit()
for b in d["aggregations"]["a"]["buckets"]: print(b["key"], b["doc_count"], sep="\t")'
}

echo "== Index d'alertes =="
q "$INDEXER_URL/_cat/indices/wazuh-alerts-*?v&s=index&h=health,index,docs.count,store.size"

echo
echo "== Contrôle croisé : label présent dans chaque index client =="
clients=$(q "$INDEXER_URL/_cat/indices/wazuh-alerts-4.x-*?h=index" \
  | sed -nE 's/^wazuh-alerts-4\.x-([a-z0-9]+)-[0-9]{4}\.[0-9]{2}\.[0-9]{2}$/\1/p' | sort -u)
status=0
for c in $clients; do
  [[ $c == unassigned ]] && continue
  labels=$(agg "wazuh-alerts-4.x-$c-*" agent.labels.client | cut -f1 | tr '\n' ' ')
  if [[ $labels == "$c " ]]; then
    printf '  %-10s OK\n' "$c"
  else
    printf '  %-10s ANOMALIE : labels trouvés = %s\n' "$c" "$labels"; status=1
  fi
done

echo
echo "== Agents dans « unassigned » (manager et agents non affectés attendus uniquement) =="
agg "wazuh-alerts-4.x-unassigned-*" agent.name | sed 's/^/  /'

exit $status
