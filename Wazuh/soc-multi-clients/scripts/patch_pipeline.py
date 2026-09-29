#!/usr/bin/env python3
"""
Modifie le pipeline d'ingestion Filebeat de Wazuh pour router chaque alerte
vers l'index de son client : wazuh-alerts-4.x-<client>-AAAA.MM.JJ

- Ajoute, après le processeur "json", un "set" (client = unassigned si absent)
  et un "lowercase" sur agent.labels.client.
- Modifie le préfixe du processeur "date_index_name".

Idempotent : le relancer sur un pipeline déjà modifié ne change rien.

Usage :
  sudo python3 patch_pipeline.py            # sauvegarde + modification
  sudo python3 patch_pipeline.py --check    # code 0 si modifié, 1 sinon
  sudo python3 patch_pipeline.py --file /chemin/pipeline.json

Après modification : sudo filebeat setup --pipelines && sudo systemctl restart filebeat
"""
import argparse
import json
import shutil
import sys
from datetime import datetime

DEFAULT_FILE = "/usr/share/filebeat/module/wazuh/alerts/ingest/pipeline.json"
FIELD = "agent.labels.client"
SET_PROC = {"set": {"field": FIELD, "value": "unassigned", "override": False}}
LOWER_PROC = {"lowercase": {"field": FIELD, "ignore_missing": True}}
OLD_PREFIX = "{{fields.index_prefix}}"
NEW_PREFIX = "{{fields.index_prefix}}{{agent.labels.client}}-"


def is_set_proc(p):
    s = p.get("set", {})
    return s.get("field") == FIELD and s.get("value") == "unassigned"


def is_lower_proc(p):
    return p.get("lowercase", {}).get("field") == FIELD


def date_index_procs(procs):
    return [p["date_index_name"] for p in procs if "date_index_name" in p]


def status(procs):
    """Retourne (set_ok, lower_ok, prefix_ok)."""
    dins = date_index_procs(procs)
    prefix_ok = bool(dins) and all(d.get("index_name_prefix") == NEW_PREFIX for d in dins)
    return (any(is_set_proc(p) for p in procs),
            any(is_lower_proc(p) for p in procs),
            prefix_ok)


def patch(procs):
    changed = False
    json_idx = next((i for i, p in enumerate(procs) if "json" in p), None)
    if json_idx is None:
        sys.exit("ERREUR : processeur 'json' introuvable dans le pipeline.")

    insert_at = json_idx + 1
    if not any(is_set_proc(p) for p in procs):
        procs.insert(insert_at, SET_PROC)
        changed = True
    if not any(is_lower_proc(p) for p in procs):
        set_idx = next(i for i, p in enumerate(procs) if is_set_proc(p))
        procs.insert(set_idx + 1, LOWER_PROC)
        changed = True

    dins = date_index_procs(procs)
    if not dins:
        sys.exit("ERREUR : processeur 'date_index_name' introuvable.")
    for d in dins:
        current = d.get("index_name_prefix")
        if current == NEW_PREFIX:
            continue
        if current != OLD_PREFIX:
            sys.exit(f"ERREUR : préfixe inattendu '{current}', modification manuelle requise.")
        d["index_name_prefix"] = NEW_PREFIX
        changed = True
    return changed


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", default=DEFAULT_FILE, help="chemin du pipeline.json")
    ap.add_argument("--check", action="store_true", help="vérifier sans modifier")
    args = ap.parse_args()

    try:
        with open(args.file, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        sys.exit(f"ERREUR : lecture de {args.file} impossible : {e}")

    procs = data.get("processors")
    if not isinstance(procs, list):
        sys.exit("ERREUR : clé 'processors' absente ou invalide.")

    set_ok, lower_ok, prefix_ok = status(procs)
    if args.check:
        print(f"set unassigned : {'OK' if set_ok else 'ABSENT'}")
        print(f"lowercase      : {'OK' if lower_ok else 'ABSENT'}")
        print(f"préfixe client : {'OK' if prefix_ok else 'ABSENT'}")
        sys.exit(0 if (set_ok and lower_ok and prefix_ok) else 1)

    if not patch(procs):
        print("Pipeline déjà modifié : rien à faire.")
        return

    backup = f"{args.file}.orig-{datetime.now():%Y%m%d-%H%M%S}"
    shutil.copy2(args.file, backup)
    with open(args.file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"Pipeline modifié. Sauvegarde : {backup}")
    print("Étape suivante : sudo filebeat setup --pipelines && sudo systemctl restart filebeat")


if __name__ == "__main__":
    main()
