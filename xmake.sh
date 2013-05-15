#!/bin/sh -x

CDIR=`pwd`
KDIR=$HOME/dev/kernel/linux-staging
RDIR=$HOME/dev/work/build/kernel
BIMAGE_NAME=linux-staging.bootimg
INITRD_IMG=initrd.img
IMAGE_LOC=$HOME/dev/work/linux/13.04/
BIMAGE=$IMAGE_LOC/$BIMAGE_NAME
TDIR=$HOME/dev/work/tools
TEGRA=$HOME/dev/work/tegra
if [ "$1" == 'clean' ]; then
	rm -rf $RDIR/*
	mkdir $RDIR/boot
fi

pushd $KDIR
if [ "$1" == 'clean' ]; then
	make -j4 ARCH=arm CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-" INSTALL_MOD_PATH="$RDIR" clean
#else
	make -j4 tegra_defconfig ARCH=arm CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-" INSTALL_MOD_PATH="$RDIR"
fi
if [ "$1" == 'image' ]; then
	make -j4 oldconfig ARCH=arm CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-" INSTALL_MOD_PATH="$RDIR" dtbs
	make -j4 oldconfig ARCH=arm CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-" INSTALL_MOD_PATH="$RDIR" zImage
	cat arch/arm/boot/dts/tegra20-paz00.dtb >> arch/arm/boot/zImage
	cp arch/arm/boot/zImage $RDIR/boot/
fi
if [ "$1" == 'modules' ]; then
	make -j4 oldconfig ARCH=arm CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-" INSTALL_MOD_PATH="$RDIR" modules
	make -j4 oldconfig ARCH=arm CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-" INSTALL_MOD_PATH="$RDIR" modules_install
fi
popd

if [ "$1" == 'image' ]; then
pushd $RDIR/boot
	cp $BIMAGE .
	cp $IMAGE_LOC/$INITRD_IMG .
	$TDIR/abootimg --create $BIMAGE_NAME -k $RDIR/boot/zImage -r $INITRD_IMG -c "cmdline = console=tty0 earlyprintk verbose debug root=/dev/mmcblk0p7 rootwait CMA=64M tegrapart=recovery:300:a00:800,boot:d00:1000:800,mbr:1d00:200:800"
	$TEGRA/nvflash --wait --bl $TEGRA/fastboot.stock.bin --download 6 $RDIR/boot/$BIMAGE_NAME
popd
fi
