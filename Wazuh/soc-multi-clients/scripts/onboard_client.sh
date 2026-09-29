#!/usr/bin/env bash
# Intègre un nouveau client sur la plateforme Wazuh mutualisée.
#
#   sudo ./onboard_client.sh <code> [--create-user <nom>] [--manager-ip <IP>]
#
# Crée (de façon idempotente) :
#   1. le groupe d'agents client-<code> et son agent.conf avec le label client: <code>
#   2. le rôle indexer client_<code>_ro (lecture seule sur wazuh-alerts-4.x-<code>-*)
#   3. le rattachement du rôle au backend role client_<code>
#   4. optionnellement un utilisateur interne (backend roles kibanauser + client_<code>)
# puis affiche les commandes d'installation des agents.
#
# Variables d'environnement facultatives :
#   INDEXER_URL       (défaut https://localhost:9200)
#   INDEXER_ADMIN_PW  (sinon demandé)
#   INDEXER_CA        (certificat de l'autorité ; sinon -k, acceptable en lab uniquement)
set -euo pipefail

WAZUH_BIN=/var/ossec/bin
SHARED=/var/ossec/etc/shared
INDEXER_URL=${INDEXER_URL:-https://localhost:9200}
API="$INDEXER_URL/_plugins/_security/api"
WAZUH_VERSION=${WAZUH_VERSION:-4.14.8}

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
log()   { printf '\033[1;34m[+]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
die()   { printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $# -ge 1 ]] || usage
CODE=$1; shift
NEW_USER=""
MANAGER_IP="<IP_MANAGER>"
while [[ $# -gt 0 ]]; do
  case $1 in
    --create-user) NEW_USER=${2:?nom manquant}; shift 2 ;;
    --manager-ip)  MANAGER_IP=${2:?IP manquante}; shift 2 ;;
    -h|--help)     usage ;;
    *)             die "option inconnue : $1" ;;
  esac
done

[[ $CODE =~ ^[a-z0-9]{2,10}$ ]] || die "code client invalide '$CODE' (2 à 10 caractères, minuscules et chiffres)"
[[ $CODE != unassigned ]] || die "'unassigned' est réservé"
[[ $EUID -eq 0 ]] || die "à lancer avec sudo (écriture dans $SHARED)"
[[ -x $WAZUH_BIN/agent_groups ]] || die "agent_groups introuvable : ce script tourne sur le manager (master)"

GROUP="client-$CODE"
ROLE="client_${CODE}_ro"
BACKEND="client_$CODE"

CURL_TLS=(-k)
[[ -n ${INDEXER_CA:-} ]] && CURL_TLS=(--cacert "$INDEXER_CA")

if [[ -z ${INDEXER_ADMIN_PW:-} ]]; then
  read -r -s -p "Mot de passe admin de l'indexer : " INDEXER_ADMIN_PW; echo
fi

# PUT JSON sur l'API de sécurité, échec si le code HTTP n'est pas 200/201
api_put() {
  local path=$1 body=$2 out code
  out=$(mktemp)
  code=$(curl -s "${CURL_TLS[@]}" -u "admin:$INDEXER_ADMIN_PW" -o "$out" -w '%{http_code}' \
         -X PUT "$API/$path" -H 'Content-Type: application/json' -d "$body")
  if [[ $code != 200 && $code != 201 ]]; then
    cat "$out" >&2; rm -f "$out"; die "PUT $path a échoué (HTTP $code)"
  fi
  rm -f "$out"
}

# Test de connexion avant toute modification
code=$(curl -s "${CURL_TLS[@]}" -u "admin:$INDEXER_ADMIN_PW" -o /dev/null -w '%{http_code}' "$INDEXER_URL")
[[ $code == 200 ]] || die "connexion à l'indexer impossible (HTTP $code) : vérifier l'URL et le mot de passe"

# 1. Groupe et label -----------------------------------------------------------
log "Groupe $GROUP"
if [[ -d $SHARED/$GROUP ]]; then
  ok "le groupe existe déjà"
else
  "$WAZUH_BIN/agent_groups" -a -g "$GROUP" -q >/dev/null
  ok "groupe créé"
fi

cat > "$SHARED/$GROUP/agent.conf" <<EOF
<agent_config>
  <labels>
    <label key="client">$CODE</label>
  </labels>
</agent_config>
EOF
chown wazuh:wazuh "$SHARED/$GROUP/agent.conf"
chmod 660 "$SHARED/$GROUP/agent.conf"
ok "label client: $CODE écrit dans $SHARED/$GROUP/agent.conf"

# 2. Rôle indexer ----------------------------------------------------------------
log "Rôle $ROLE"
api_put "roles/$ROLE" "{
  \"cluster_permissions\": [\"cluster_composite_ops_ro\"],
  \"index_permissions\": [{
    \"index_patterns\": [\"wazuh-alerts-4.x-$CODE-*\"],
    \"allowed_actions\": [\"read\"]
  }]
}"
ok "lecture seule sur wazuh-alerts-4.x-$CODE-*"

# 3. Rattachement ----------------------------------------------------------------
log "Rattachement $ROLE <- backend role $BACKEND"
api_put "rolesmapping/$ROLE" "{ \"backend_roles\": [\"$BACKEND\"] }"
ok "rattachement créé"

# 4. Utilisateur (optionnel) -------------------------------------------------------
if [[ -n $NEW_USER ]]; then
  log "Utilisateur $NEW_USER"
  read -r -s -p "Mot de passe pour $NEW_USER : " USER_PW; echo
  [[ ${#USER_PW} -ge 12 ]] || die "mot de passe trop court (12 caractères minimum)"
  USER_PW_JSON=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$USER_PW")
  api_put "internalusers/$NEW_USER" "{
    \"password\": $USER_PW_JSON,
    \"backend_roles\": [\"kibanauser\", \"$BACKEND\"],
    \"description\": \"Compte client $CODE\"
  }"
  unset USER_PW USER_PW_JSON
  ok "utilisateur créé (lecture seule, périmètre $CODE)"
fi

# 5. Commandes d'installation des agents ----------------------------------------------
UPPER=$(tr '[:lower:]' '[:upper:]' <<<"$CODE")
cat <<EOF

==================== Déploiement des agents ($CODE) ====================
Linux (dépôt Wazuh configuré) :
  sudo WAZUH_MANAGER="$MANAGER_IP" WAZUH_AGENT_GROUP="$GROUP" WAZUH_AGENT_NAME="$UPPER-\$(hostname)" \\
    apt-get install -y wazuh-agent=$WAZUH_VERSION-1
  sudo systemctl daemon-reload && sudo systemctl enable --now wazuh-agent

Windows (PowerShell administrateur) :
  msiexec /i wazuh-agent-$WAZUH_VERSION-1.msi /q WAZUH_MANAGER="$MANAGER_IP" \`
    WAZUH_AGENT_GROUP="$GROUP" WAZUH_AGENT_NAME="$UPPER-\$env:COMPUTERNAME"
  NET START WazuhSvc

Reste à faire manuellement :
  - RBAC de l'API Wazuh pour le groupe $GROUP (docs/05-rbac-api-wazuh.md)
  - politique de rétention ISM si différente du standard
Vérifications :
  sudo $WAZUH_BIN/agent_groups -l -g $GROUP
  ./audit_routage.sh
=========================================================================
EOF
