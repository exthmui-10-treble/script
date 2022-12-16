#!/bin/bash
echo
echo "-----------------------------------------"
echo "       exTHmUI 10 Treble Buildbot        "
echo "                  by                     "
echo "               xiaoleGun                 "
echo " Executing in 3 seconds - CTRL-C to exit "
echo "-----------------------------------------"
echo

sleep 3
set -e

BL=$(cd $(dirname $0);pwd)
BD=$HOME/builds

mkdir -p $BD

initRepo() {
if [ ! -d .repo ]
then
    echo ""
    echo "--> Initializing exTHmUI workspace"
    echo ""
    repo init -u https://github.com/exthmui-10-treble/android --depth=1
fi
}

syncRepo() {
echo ""
echo "--> Syncing repos"
echo ""
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
}

buildTreble() {
    echo ""
    echo "--> Building treble image"
    echo ""
    . build/envsetup.sh
    lunch exthm_treble_arm64_bvN-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    mv $OUT/system.img $BD/system-exthm_treble_arm64_bvN.img
}

buildSasImages() {
    echo ""
    echo "--> Building vndklite variant"
    echo ""
    cd sas-creator
    sudo bash lite-adapter.sh 64 $BD/system-exthm_treble_arm64_bvN.img
    cp s.img $BD/system-exthm_treble_arm64_bvN-vndklite.img
    sudo rm -rf s.img d tmp
    cd ..
}

generatePackages() {
    echo ""
    echo "--> Generating packages"
    echo ""
    BASE_IMAGE=$BD/system-exthm_treble_arm64_bvN.img
    mkdir --parents $BD/dsu/vanilla/; mv $BASE_IMAGE $BD/dsu/vanilla/system.img
    zip -j -v $BD/exTHmUI-10-arm64-ab-$BUILD_DATE-UNOFFICIAL.zip $BD/dsu/vanilla/system.img
    mkdir --parents $BD/dsu/vanilla-vndklite/; mv ${BASE_IMAGE%.img}-vndklite.img $BD/dsu/vanilla-vndklite/system.img
    zip -j -v $BD/exTHmUI-10-arm64-ab-vndklite-$BUILD_DATE-UNOFFICIAL.zip $BD/dsu/vanilla-vndklite/system.img
    rm -rf $BD/dsu
}

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

initRepo
syncRepo
buildTreble
buildSasImages
generatePackages

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo ""
echo "--> Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
