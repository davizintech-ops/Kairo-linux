#!/bin/bash
set -e

error() {
    local CODE="$1"
    shift

    echo
    echo "=========================================="
    echo "           Kairo Build Error"
    echo "=========================================="
    echo
    echo "Error Code : $CODE"
    echo "Message    : $*"
    echo
    echo "Build aborted."
    echo "=========================================="
    exit "$CODE"
}

[ -n "$TERMUX_VERSION" ] && error 10 "Termux is not supported."

[ "$EUID" -ne 0 ] && error 11 "Run this script as root."

command -v debootstrap >/dev/null || \
    error 12 "debootstrap is not installed."

command -v mksquashfs >/dev/null || \
    error 13 "squashfs-tools is not installed."

[ -d "../rootfs" ] && \
    error 14 "RootFS directory already exists."


ROOTFS="../rootfs"
RELEASE="bookworm"
ARCH="i386"
MIRROR="http://deb.debian.org/debian"

clear

echo "=========================================="
echo "      Kairo Linux Build System"
echo "=========================================="
echo

# Não permitir Termux
if [ -n "$TERMUX_VERSION" ]; then
cat << EOF

ERROR: Termux is not supported.

Reason:
 • Missing required system features.
 • Incompatible build environment.

Please build Kairo Linux on a native
GNU/Linux distribution.

Supported:
 ✔ Debian
 ✔ Ubuntu
 ✔ Linux Mint
 ✔ Arch Linux

Aborting...

EOF
exit 1
fi

# Verifica root
if [ "$EUID" -ne 0 ]; then
    echo "Execute como root:"
    echo "sudo ./make-rootfs.sh"
    exit 1
fi

# Verifica debootstrap
command -v debootstrap >/dev/null || {
    echo "debootstrap não encontrado."
    echo "Instale com:"
    echo "apt install debootstrap"
    exit 1
}

echo "[1/7] Removendo rootfs antigo..."
rm -rf "$ROOTFS"

echo "[2/7] Criando diretório..."
mkdir -p "$ROOTFS"

echo "[3/7] Criando Debian Base..."
debootstrap \
    --arch=$ARCH \
    --variant=minbase \
    "$RELEASE" \
    "$ROOTFS" \
    "$MIRROR"

echo "[4/7] Montando pseudo-filesystems..."
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"
mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sys "$ROOTFS/sys"

echo "[5/7] Configurando DNS..."
cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

echo "[6/7] Definindo hostname..."
echo "kairo" > "$ROOTFS/etc/hostname"

cat > "$ROOTFS/etc/hosts" <<EOF
127.0.0.1 localhost
127.0.1.1 kairo
EOF

echo "[7/7] Finalizado!"

echo
echo "=========================================="
echo " RootFS criado com sucesso!"
echo "=========================================="
echo
echo "Entre com:"
echo
echo "sudo chroot $ROOTFS"
