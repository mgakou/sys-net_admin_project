# 08 — Feuille de route

| Étape | Statut |
|---|---|
| Groupes et labels par client | ✅ Fait |
| Stack alignée en 4.14.8 | ✅ Fait |
| Pipeline : un index par client, créé automatiquement | ✅ Fait, testé |
| Rôle indexer par client + tests d'isolation (200 / 403) | ✅ Fait |
| `do_not_fail_on_forbidden` (dashboard utilisable par un client) | ✅ Fait |
| Scripts : patch du pipeline, onboarding, audit, tests d'isolation | ✅ Fait |
| RBAC de l'API Wazuh (liste des agents filtrée par client) | 🔄 En cours |
| Restriction des tenants (retrait du tenant global pour les clients) | ⏳ |
| Rétention ISM par client | ⏳ |
| Segmentation pfSense : zones SOC / Client A / Client B / Attaquant | ⏳ |
| Remontée syslog de pfSense vers un relais client | ⏳ |
| Passage en cluster : ajout d'un worker (master/worker) | ⏳ |
| Scénarios d'attaque depuis Kali (brute force, scans, persistance) et vérification du rangement | ⏳ |
| Tuning de l'agent bruyant `labsiem-service` (~2 500 alertes en quelques minutes) | ⏳ |
