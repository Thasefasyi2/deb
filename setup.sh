#!/bin/bash
# ================================================================
# Debian 12 (Bookworm) Server Setup Script
# Docker + Docker Compose + Cloudflared + SSH Server
# ================================================================

set -e

echo "🚀 Memulai setup server Debian 12 (Bookworm)..."

# ----------------------------------------------------------------
# 1. Update dan install dependensi dasar
# ----------------------------------------------------------------
echo "📦 Memperbarui sistem dan menginstal paket pendukung..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget gnupg ca-certificates lsb-release apt-transport-https

# ----------------------------------------------------------------
# 2. Instalasi Docker (repositori resmi)
# ----------------------------------------------------------------
echo "🐋 Menginstal Docker dan Compose plugin..."

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

# ----------------------------------------------------------------
# 3. Tambahkan user ke grup docker
# ----------------------------------------------------------------
if id "$USER" &>/dev/null; then
    echo "👤 Menambahkan user '$USER' ke grup docker..."
    sudo usermod -aG docker $USER
else
    echo "⚠️  User '$USER' tidak ditemukan, lewati langkah grup docker."
fi

# ----------------------------------------------------------------
# 4. Instalasi Cloudflared
# ----------------------------------------------------------------
echo "☁️  Menginstal Cloudflared (tunnel CLI)..."

wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared.deb
sudo dpkg -i /tmp/cloudflared.deb
rm /tmp/cloudflared.deb

if command -v cloudflared >/dev/null 2>&1; then
    echo "✅ Cloudflared berhasil diinstal: $(cloudflared --version)"
else
    echo "❌ Gagal menginstal Cloudflared."
fi

# ----------------------------------------------------------------
# 5. Instalasi dan konfigurasi SSH server
# ----------------------------------------------------------------
echo "🔐 Menginstal dan mengaktifkan OpenSSH server..."

sudo apt install -y openssh-server

sudo systemctl enable ssh
sudo systemctl start ssh

# Amankan konfigurasi dasar SSH (opsional tapi disarankan)
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

sudo systemctl restart ssh

IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ SSH server aktif."
echo "   > Coba konek lewat: ssh $USER@${IP_ADDR}"
echo "   (Gunakan IP di atas atau tunnel Cloudflare bila sudah disetup.)"

# ----------------------------------------------------------------
# 6. Info akhir
# ----------------------------------------------------------------
echo ""
echo "🎉 Instalasi selesai!"
echo ""
echo "➡️  Silakan logout & login ulang agar grup 'docker' aktif."
echo "➡️  Untuk mulai setup tunnel Cloudflare:"
echo "    cloudflared tunnel login"
echo "    cloudflared tunnel create my-tunnel"
echo ""
echo "✅ Docker info:"
sudo docker --version
sudo docker compose version
echo ""
echo "✅ Cloudflared info:"
cloudflared --version
echo ""
echo "✅ SSH info:"
systemctl status ssh --no-pager | grep Active
echo ""
echo "✨ Server siap digunakan!"
