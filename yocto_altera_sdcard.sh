#!/bi/bash
#
# Creating SD card for Altera Cyclone5 Soc
# Usage: source yocto_altera_install

yellow='\E[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]
then
  sudo lsblk
  echo -e "${yellow}Please provide a drive name:${NC}"
  read prt
  echo -e "${yellow}Please provide an image name:${NC}"
  read img
else
  prt=${1}
fi


echo -e "${yellow}Creating Yocto image for Altera-SoC...${NC}"
cd ..
if [ -f *sdimage-cyclone5* ]
then
  rm *sdimage-cyclone5*
fi

wic create sdimage-cyclone5-arria5 -e ${img}
retval=$?
if [ ${retval} -eq 0 ]
then
  if [ -f *sdimage-cyclone5* ]
  then
    umount /dev/${prt}1
    umount /dev/${prt}2
    mv sdimage-cyclone5-*.direct sdimage-cyclone5.direct
    echo -e "${yellow}Flashing SD card...${NC}"
    sudo dd if=./sdimage-cyclone5.direct of=/dev/${prt}
    umount /dev/${prt}1
    umount /dev/${prt}2
    cd $OLDPWD
    echo -e "${yellow}Success: SD card is ready!${NC}"
  else
    cd $OLDPWD
    echo -e "${yellow}Fail: No image file was found!${NC}"
  fi
else
  cd $OLDPWD
  echo -e "${yellow}Fail: Image creating tool failed!${NC}"
fi
