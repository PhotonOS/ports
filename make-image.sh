#!/bin/sh -e

readonly PROGNAME='make-image'
readonly PROGVERSION='0.0.1'

#=============================  M a i n  ==============================#

while [ $# -gt 0 ]; do
	n=2
	case "$1" in
		-t | --tag) TAG="$2";;
		-a | --arch) ARCH="$2";;
		-r | --repositories-file) REPOSITORIES_FILE="$2";;
		-p | --packages-file) PACKAGES_FILE="$2";;
		-w | --workdir) WORK_DIR="$2";;
		-o | --outdir) OUT_DIR="$2";;
		-n | --name) NAME="$2";;
		-v | --version) VERSION="$2";;
		     --apkovl) APKOVL="$2";;
		     --storage-size) STORAGE_SIZE="$2";; # In Megabytes
		-h | --help) echo "$PROGNAME $PROGVERSION"; exit 0;;
		--) shift; break;;
	esac
	shift $n
done

echo "------ Install Toolchain ------"
apk add --no-cache alpine-sdk \
build-base apk-tools \
alpine-conf \
busybox \
fakeroot \
syslinux \
openssl \
xorriso \
openrc \
squashfs-tools \
cryptsetup \
util-linux \
e2fsprogs \
gawk \
tree \
shadow \
sudo

echo "----- Installing EFI Tools ------"
apk add mtools \
dosfstools \
grub-efi

echo "-------- Update APK Index --------"
apk update

echo "----- Add 'root' to 'abuild' -----"
addgroup -S root abuild

echo "------- Create Signing Key -------"
abuild-keygen -i -a -q -n

echo "----------- Make Image -----------"
APKOVL=$APKOVL \
APKS=$(awk '{sub(/@.*/, ""); print}' $PACKAGES_FILE | tr '\n' ' ') \
    "$(dirname "$0")"/scripts/mkimage.sh --tag ${TAG} \
    --outdir ${OUT_DIR} \
    --arch ${ARCH} \
    $(awk 'NF>0{print $NF}' $REPOSITORIES_FILE | sed -e 's/^/--repository /') \
    --profile ${ARCH} \
    --name ${NAME} \
    --version ${VERSION} \
    --workdir ${WORK_DIR}

echo "-------- Partition Image ---------"
FILENAME=${OUT_DIR}/${NAME}-${TAG}-${VERSION}-${ARCH}.iso
LAST_SECTOR=$(fdisk -lu $FILENAME | grep iso1 | awk '{ print $4 }')
NEXT_SECTOR=$((LAST_SECTOR + 1))
BLOCKSIZE=512
LOOP=/dev/loop9
mknod -m640 $LOOP b 7 9 # Increment last number too
chown root:disk $LOOP

fdisk -lu $FILENAME
SECTOR_SIZE=$((STORAGE_SIZE * 1000000 / BLOCKSIZE))

dd if=/dev/zero bs=$BLOCKSIZE count=$SECTOR_SIZE >> $FILENAME

sfdisk --append $FILENAME << EOF
$NEXT_SECTOR,$SECTOR_SIZE
EOF

echo $((NEXT_SECTOR * BLOCKSIZE))
losetup -o $((NEXT_SECTOR * BLOCKSIZE)) $LOOP $FILENAME
mkfs.ext4 $LOOP
fsck -fv -p $LOOP
fdisk -lu $FILENAME

echo "---------- Create LUKS ------------"
openssl genrsa -out ${OUT_DIR}/luks.key 4096
chmod 400 ${OUT_DIR}/luks.key

cryptsetup luksFormat -q $LOOP --key-file ${OUT_DIR}/luks.key

# Mount Storage
cryptsetup luksOpen $LOOP cache --key-file ${OUT_DIR}/luks.key 
mkfs.ext4 /dev/mapper/cache
mkdir /cache
mount /dev/mapper/cache /cache

# Verify
cryptsetup -v isLuks $LOOP
df -h /cache
fdisk -lu $FILENAME
