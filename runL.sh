#!/bin/bash

# =====================================
# Script: run.sh (versi Debian 13 / Linux)
# Deskripsi:
#   - Membuat folder data untuk n8n jika belum ada
#   - Menjalankan container Docker n8n
#   - Jika container sudah ada: jalankan ulang jika berhenti
# =====================================

CONTAINER_NAME="n8n_bash"
IMAGE_NAME="docker.io/n8nio/n8n:latest"
DATA_FOLDER="${PWD}/n8n_data"

# 1. Pastikan folder data ada
if [ ! -d "$DATA_FOLDER" ]; then
  echo "📁 Folder n8n_data belum ada. Membuat..."
  mkdir -p "$DATA_FOLDER"
else
  echo "✅ Folder n8n_data sudah ada."
fi

# 2. Cek apakah container sudah ada
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "🔹 Container ${CONTAINER_NAME} sudah ada."
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "▶️ Container ${CONTAINER_NAME} sedang berjalan."
  else
    echo "⏯️ Container ${CONTAINER_NAME} berhenti. Menjalankan ulang..."
    docker start "${CONTAINER_NAME}"
  fi
else
  echo "🚀 Membuat dan menjalankan container baru: ${CONTAINER_NAME}..."
  docker run -d \
    -p 5678:5678 \
    -v "${DATA_FOLDER}:/home/node/.n8n" \
    -e N8N_COMMUNITY_PACKAGES_ALLOW=true \
    -e N8N_EDITOR_BASE_URL="https://verse-robust-slowly-society.trycloudflare.com" \
    -e WEBHOOK_URL="https://verse-robust-slowly-society.trycloudflare.com" \
    -e N8N_DEFAULT_BINARY_DATA_MODE=filesystem \
    --name "${CONTAINER_NAME}" \
    "${IMAGE_NAME}"
fi
