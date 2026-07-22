#!/bin/bash

# Encerra o script se houver qualquer erro não tratado
set -e

# Detecta quem é o usuário comum que chamou o sudo
USUARIO_REAL=${SUDO_USER:-$USER}

CAMINHO_BACKUP=$1

# 1. Valida se o caminho do backup foi informado
if [ -z "$CAMINHO_BACKUP" ]; then
  echo "❌ Uso: sudo $0 /caminho/para/pasta_de_backup"
  echo "Exemplo: sudo $0 /var/backups/backup_2026-07-22_15-00"
  exit 1
fi

# 2. Valida se está rodando como sudo/root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Este script de restauração precisa de permissões de root."
  echo "   Execute com: sudo $0 $CAMINHO_BACKUP"
  exit 1
fi

echo "📦 [1/5] Restaurando arquivos do Nextcloud..."
mkdir -p ./nextcloud_data
rsync -a "$CAMINHO_BACKUP/nextcloud_data/" ./nextcloud_data/

echo "🗄️ [2/5] Restaurando banco de dados e preparando permissões..."
mkdir -p ./databases

# 1. Copia o backup do SQL
cp "$CAMINHO_BACKUP/databases/01-restore.sql" ./databases/

# 2. Extrai a senha do config.php de forma automática
SENHA_DB=$(grep "'dbpassword'" ./nextcloud_data/config/config.php | cut -d"'" -f4)

# 3. Cria o 00-init-user.sql (roda PRIMEIRO de tudo)
cat <<EOF > ./databases/00-init-user.sql
CREATE USER oc_admin WITH PASSWORD '$SENHA_DB';
GRANT ALL PRIVILEGES ON DATABASE tardis_db TO oc_admin;
ALTER DATABASE tardis_db OWNER TO oc_admin;
EOF

# 4. Cria o 02-grant-permissions.sql (roda LOGO APÓS a restauração das tabelas)
cat <<EOF > ./databases/02-grant-permissions.sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO oc_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO oc_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO oc_admin;
EOF

echo "📄 [3/5] Restaurando configurações (.env e docker-compose.yml)..."
cp "$CAMINHO_BACKUP/.env" ./
cp "$CAMINHO_BACKUP/docker-compose.yml" ./

echo "🔑 [4/5] Ajustando permissões dos arquivos do projeto..."
chown -R "$USUARIO_REAL:$USUARIO_REAL" ./
chown -R 33:33 ./nextcloud_data

echo "🚀 [5/5] Subindo os contêineres no Docker..."
docker compose up -d

echo "✅ Restauração concluída com sucesso e zero intervenção manual!"