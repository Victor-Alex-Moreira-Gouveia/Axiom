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

echo "📦 [1/5] Restaurando arquivos do Nextcloud (com permissão de superusuário)..."
# Usamos rsync para preservar atributos de arquivo e cópia eficiente
mkdir -p ./nextcloud_data
rsync -a "$CAMINHO_BACKUP/nextcloud_data/" ./nextcloud_data/

echo "🗄️ [2/5] Restaurando script SQL de inicialização do banco..."
mkdir -p ./databases
cp "$CAMINHO_BACKUP/databases/01-restore.sql" ./databases/

echo "📄 [3/5] Restaurando configurações (.env e docker-compose.yml)..."
cp "$CAMINHO_BACKUP/.env" ./
cp "$CAMINHO_BACKUP/docker-compose.yml" ./

echo "🔑 [4/5] Ajustando permissões dos arquivos do projeto..."
# Permite que o seu usuário comum gerencie os arquivos locais
chown -R "$USUARIO_REAL:$USUARIO_REAL" ./

echo "🚀 [5/5] Subindo os contêineres no Docker..."
docker compose up -d

echo "✅ Restauração concluída com sucesso!"