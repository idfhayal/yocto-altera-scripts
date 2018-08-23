#!/bi/bash
#
# Creating SD card for Altera Cyclone5 Soc
# Usage: source yocto_altera_install

yellow='\E[1;33m'
NC='\033[0m'


if [ $# -eq 0 ]
then
  lsblk
  echo -e "${yellow}Please provide a partition:${NC}"
  read prt
else
  prt=${1}
fi

echo -e "${yellow}Creating Yocto Rocko SD card for Altera-SoC...${NC}"
if [ -f ../*sdimage-cyclone5* ]
then
  rm ../*sdimage-cyclone5*
fi

cd ..
wic create sdimage-cyclone5-arria5 -e core-image-minimal
umount /dev/${prt}1
umount /dev/${prt}2
mv sdimage-cyclone5-*.direct sdimage-cyclone5.direct
sudo dd if=./sdimage-cyclone5.direct of=/dev/${prt}
umount /dev/${prt}1
umount /dev/${prt}2
cd $OLDPWD
echo -e "${yellow}SD card is ready!${NC}"
