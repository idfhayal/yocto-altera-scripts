#!/bi/sh - run in shell
#
# Creating SD card for Altera Cyclone5 Soc
# Usage: source yocto_altera_install

yellow='\E[1;33m'
NC='\033[0m'

echo -e "${yellow}Creating Yocto Rocko SD card for Altera-SoC...${NC}"
cd ~/poky/build
rm *sdimage-cyclone5*
wic create sdimage-cyclone5-arria5 -e core-image-minimal
umount /dev/sdb1
umount /dev/sdb2
mv sdimage-cyclone5-*.direct sdimage-cyclone5.direct
sudo dd if=./sdimage-cyclone5.direct of=/dev/sdb
umount /dev/sdb1
umount /dev/sdb2
echo -e "${yellow}SD card is ready!${NC}"
