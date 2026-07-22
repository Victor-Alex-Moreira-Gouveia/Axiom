#!/bin/bash

set -e

USUARIO_REAL=${SUDO_USER:-$USER}
DATA=$(date +%Y-%m-%d_%H-%M)
PASTA_PROJETO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASTA_BACKUP="/var/backups"
DIRETORIO_ATUAL="$PASTA_BACKUP/backup_$DATA"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Execute com sudo: sudo $0"
  exit 1
fi

echo "🚀 [1/4] Criando estrutura de backup..."
mkdir -p "$DIRETORIO_ATUAL/databases"

echo "🗄️ [2/4] Gerando arquivo SQL de restauração automática..."
# Salva o dump diretamente com o nome de inicialização do Postgres
docker exec -t DB_Server pg_dump -U user_admin -d tardis_db --clean --if-exists > "$DIRETORIO_ATUAL/databases/01-restore.sql"

echo "📂 [3/4] Copiando arquivos do Nextcloud..."
rsync -avz --delete "$PASTA_PROJETO/nextcloud_data/" "$DIRETORIO_ATUAL/nextcloud_data/"

echo "📄 [4/4] Copiando arquivos de configuração (.env e compose)..."
cp "$PASTA_PROJETO/.env" "$DIRETORIO_ATUAL/.env"
cp "$PASTA_PROJETO/docker-compose.yml" "$DIRETORIO_ATUAL/docker-compose.yml"

# Limpeza de backups antigos (> 30 dias)
find "$PASTA_BACKUP" -mindepth 1 -maxdepth 1 -type d -name "backup_*" -mtime +30 -exec rm -rf {} +

chown -R "$USUARIO_REAL:$USUARIO_REAL" "$DIRETORIO_ATUAL"

echo "✅ Backup completo gerado em: $DIRETORIO_ATUAL"