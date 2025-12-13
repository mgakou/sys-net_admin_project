{\rtf1\ansi\ansicpg1252\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/bin/bash\
\
# Script de durcissement automatique des services systemd\
# Applique des mesures de confinement selon la priorit\'e9 (niveau 1 et 2)\
\
# Services prioritaire niveau 1\
PRIO1=(\
  ssh.service\
  NetworkManager.service\
  fail2ban.service\
  snapd.service\
  cron.service\
  fwupd.service\
  rsyslog.service\
)\
\
# Services prioritaire niveau 2\
PRIO2=(\
  gdm.service\
  udisks2.service\
  cups.service\
  getty@tty1.service\
  gnome-remote-desktop.service\
  open-vm-tools.service\
)\
\
# Fonction de durcissement g\'e9n\'e9rique (\'e9criture manuelle de override.conf)\
durcir_service() \{\
  local SERVICE=$1\
  echo "\uc0\u55357 \u56594  Durcissement de $SERVICE..."\
\
  local DIR="/etc/systemd/system/$\{SERVICE\}.d"\
  local FILE="$\{DIR\}/override.conf"\
\
  sudo mkdir -p "$DIR"\
\
  sudo tee "$FILE" > /dev/null <<EOF\
[Service]\
ProtectSystem=strict\
ProtectHome=yes\
PrivateTmp=yes\
NoNewPrivileges=yes\
ReadOnlyPaths=/etc\
CapabilityBoundingSet=\
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX\
EOF\
\
  echo "\uc0\u9989  $SERVICE renforc\'e9."\
\}\
\
# Appliquer aux services de priorit\'e9 1\
echo -e "\\n=== Renforcement des services PRIORIT\'c9 1 ==="\
for svc in "$\{PRIO1[@]\}"; do\
  durcir_service "$svc"\
done\
\
# Appliquer aux services de priorit\'e9 2 (optionnel)\
echo -e "\\n=== Renforcement des services PRIORIT\'c9 2 (optionnel) ==="\
read -p "Souhaitez-vous aussi renforcer les services de priorit\'e9 2 ? (y/n): " confirm\
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then\
  for svc in "$\{PRIO2[@]\}"; do\
    durcir_service "$svc"\
  done\
else\
  echo "\uc0\u9197 \u65039  Services de priorit\'e9 2 ignor\'e9s."\
fi\
\
# Reload systemd\
sudo systemctl daemon-reexec\
sudo systemctl daemon-reload\
\
echo -e "\\n\uc0\u9989  Tous les services s\'e9lectionn\'e9s ont \'e9t\'e9 trait\'e9s."}