#!/bi/sh - run in shell
#
# Building Yocto for Altera Cyclone5 SoC
# Author: Alex Sh
# Usage: source yocto_altera_install


yellow='\E[1;33m'
NC='\033[0m'

### Parameters #############################################################
url_yocto="git://git.yoctoproject.org/poky.git"
url_altera="git://github.com/kraj/meta-altera.git"
url_toolchain="git://git.linaro.org/openembedded/meta-linaro.git"
bspDir="altera-source"
buildDir="altera-build"
customLayer="meta-custom-altera"
machine="cyclone-custom-machine"

### Functions #############################################################
function patchToolchain
{
  # BSP Dir
  cd ${bspDirAbs}

  echo -e "${yellow}Patching Linaro Toolchain...${NC}"
  echo "TARGET_CC_ARCH += "'"${LDFLAGS}"'"" >> meta-linaro/meta-linaro-toolchain/recipes-devtools/gcc/libgcc_linaro-5.2.bb
}

function download
{
  echo -e "${yellow}Downloading sources for Altera-SoC...${NC}"
  echo -e "${yellow}Choose preferred Yocto version...${NC}"
  git ls-remote --heads ${url_yocto}
  echo -e "${yellow}Type branch name...${NC}"
  read branch
  
  # Download Yocto source
  echo -e "${yellow}Downloading Yocto ${branch} source...${NC}"
  mainDir="yocto-${branch}"
  git clone -b ${branch} ${url_yocto} ${mainDir}
  cd ${mainDir}
}

function reset
{
  # Main Dir
  cd ${mainDirAbs}
  git reset HEAD --hard
  git clean -fxd
  rm -rf ${buildDir}
}

function bspDownload
{
  # Main Dir
  cd ${mainDirAbs}

  mkdir ${bspDir}
  cd ${bspDirAbs} 
  # BSP Dir

  # Download Altera BSP
  echo -e "${yellow}Downloading meta-altera...${NC}"
  git clone -b ${branch} ${url_altera}

  # Download Toolchain
  echo -e "${yellow}Downloading meta-linaro...${NC}"
  git clone -b ${branch} ${url_toolchain}
  
  patchToolchain

  # BSP Dir
}


function environment
{
  # Main Dir
  cd ${mainDirAbs}

  echo -e "${yellow}Setting up environment...${NC}"
  # echo -e "${yellow}Enter build directory name...${NC}"
  # read name
  # buildDir="${name}-build"
  source oe-init-build-env ${buildDir}
}

function buildConfig
{
  # Build Dir
  cd ${buildDirAbs}

  echo -e "${yellow}Setting up build configuration...${NC}"
  cp -n conf/local.conf conf/local.conf.sample
  cp -n conf/bblayers.conf conf/bblayers.conf.sample
  echo " " >> conf/local.conf
  echo "#" >> conf/local.conf
  echo "# Custom configuration" >> conf/local.conf
  echo "#" >> conf/local.conf
  echo "BB_NUMBER_THREADS = "'"6"'"" >> conf/local.conf
  echo "PARALLEL_MAKE = "'"-j 8"'"" >> conf/local.conf
  echo "DL_DIR = "'"${TOPDIR}/../downloads"'"" >> conf/local.conf
  echo "SSTATE_DIR = "'"${TOPDIR}/../sstate-cache"'"" >> conf/local.conf
}

function buildConfig_de0
{
  # Build Dir
  cd ${buildDirAbs}

  echo " " >> conf/local.conf
  echo "#" >> conf/local.conf
  echo "# Machine configuration" >> conf/local.conf
  echo "#" >> conf/local.conf
  echo "MACHINE = "'"cyclone5"'"" >> conf/local.conf
  echo "PREFERRED_PROVIDER_virtual/kernel = "'"linux-altera-ltsi-rt"'"" >> conf/local.conf
  echo "PREFERRED_VERSION_linux-altera-ltsi-rt = "'"4.9%"'"" >> conf/local.conf
  echo "GCCVERSION = "'"linaro-5.2"'"" >> conf/local.conf
  echo "SDKGCCVERSION = "'"linaro-5.2"'"" >> conf/local.conf
  echo "DEFAULTTUNE = "'"cortexa9hf-neon"'"" >> conf/local.conf
  echo "UBOOT_CONFIG = "'"de0-nano-soc"'"" >> conf/local.conf
  echo "KERNEL_DEVICETREE = "'"socfpga_cyclone5_de0_sockit.dtb"'"" >> conf/local.conf
  echo "UBOOT_EXTLINUX_FDT = "'"../socfpga_cyclone5_de0_sockit.dtb"'"" >> conf/local.conf
  echo "PACKAGE_CLASSES = "'"package_ipk"'"" >> conf/local.conf
}




function addLayers
{
  cd ${buildDirAbs}
  # Build Dir

  echo -e "${yellow}Adding layers...${NC}"
  bitbake-layers add-layer ../${bspDir}/meta-altera
  bitbake-layers add-layer ../${bspDir}/meta-linaro/meta-linaro-toolchain

  cd ${mainDirAbs}
  #Main Dir
}



function customMeta
{
  # Main Dir
  cd ${mainDirAbs}
  
  bitbake-layers create-layer ${bspDir}/${customLayer}

  cd ${buildDirAbs}
  bitbake-layers add-layer ../${bspDir}/${customLayer}
  # Build Dir
}

function customMachine
{
  # Custom layer Dir
  cd ${customLayerAbs}

  echo -e "${yellow}Creating custom target Machine...${NC}"
  mkdir conf/machine
  touch conf/machine/${machine}.conf
  echo "#@TYPE: Machine" >> conf/machine/${machine}.conf
  echo "#@NAME: Cyclone5 Custom Machine" >> conf/machine/${machine}.conf
  echo "#@DESCRIPTION: Custom Machine configuration for the Cyclone V SoC" >> conf/machine/${machine}.conf
  echo "#@MAINTAINER: Alex Sh" >> conf/machine/${machine}.conf
  echo " " >> conf/machine/${machine}.conf
  echo "require conf/machine/cyclone5.conf" >> conf/machine/${machine}.conf
  echo "UBOOT_CONFIG = "'"de0-nano-soc"'"" >> conf/machine/${machine}.conf
  echo "KERNEL_DEVICETREE = "'"socfpga_cyclone5_de0_sockit.dtb"'"" >> conf/machine/${machine}.conf
  echo "UBOOT_EXTLINUX_FDT = "'"../socfpga_cyclone5_de0_sockit.dtb"'"" >> conf/machine/${machine}.conf
}

function customBuildConfig
{
  cd ${customLayerAbs}
  # Custom layer Dir

  echo -e "${yellow}Configuring custom BSP...${NC}"
  cp -n conf/layer.conf conf/layer.conf.sample
  echo " " >> conf/layer.conf
  echo "# Dependencies" >> conf/layer.conf
  # echo "LAYERDEPENDS_cyclone-custom-bsp = "'"meta-altera"'"" >> conf/layer.conf
  # echo "LAYERVERSION_cyclone-custom-bsp = "'"1"'"" >> conf/layer.conf
  echo "LAYERDEPENDS_${customLayer} = "'"meta-altera"'"" >> conf/layer.conf
  echo "LAYERVERSION_${customLayer} = "'"1"'"" >> conf/layer.conf
  echo " " >> conf/layer.conf
  echo "#" >> conf/layer.conf
  echo "# Custom Altera-SoC configuration" >> conf/layer.conf
  echo "#" >> conf/layer.conf
  echo "PACKAGE_CLASSES = "'"package_ipk"'"" >> conf/layer.conf
  echo "MACHINE = "'"'${machine}'"'"" >> conf/layer.conf
  echo "PREFERRED_PROVIDER_virtual/kernel = "'"linux-altera-ltsi-rt"'"" >> conf/layer.conf
  echo "PREFERRED_VERSION_linux-altera-ltsi-rt = "'"4.9%"'"" >> conf/layer.conf
  echo "GCCVERSION = "'"linaro-5.2"'"" >> conf/layer.conf
  echo "SDKGCCVERSION = "'"linaro-5.2"'"" >> conf/layer.conf
  echo "DEFAULTTUNE = "'"cortexa9hf-neon"'"" >> conf/layer.conf
  
  cd ${mainDirAbs}
  #Main Dir
}

### Main #############################################################

echo -e "${yellow}1. Download Yocto source? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  download
fi

mainDirAbs=$(pwd)
buildDirAbs=${mainDirAbs}/${buildDir}
bspDirAbs=${mainDirAbs}/${bspDir}
customLayerAbs=${bspDirAbs}/${customLayer}

echo -e "${yellow}2. Download Alters SoC BSP? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  bspDownload
fi


echo -e "${yellow}2. Reset yocto built? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  reset
fi

echo -e "${yellow}2. Init environment? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  environment
fi

echo -e "${yellow}4. Add layers? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  addLayers
fi

echo -e "${yellow}3. Edit build configuration? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  buildConfig
fi

echo -e "${yellow}4. Build config for De0-Nano? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  buildConfig_de0
fi

echo -e "${yellow}5. Add custom layer? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  customMeta
fi

echo -e "${yellow}6. Add custom machine? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  customMachine
fi

echo -e "${yellow}7. Edit custom layer build configuration? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  customBuildConfig
fi

echo -e "${yellow}8. Build U-boot? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  cd ${buildDirAbs} 
  echo -e "${yellow}Build U-Boot:${NC}"
  bitbake -k virtual/bootloader
fi

echo -e "${yellow}8. Build Linux Kernel? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  cd ${buildDirAbs}
  bitbake -c menuconfig virtual/kernel
  bitbake -k virtual/kernel
fi

echo -e "${yellow}8. Build RootFS? [y/n]${NC}"
read yn
if [ ${yn} == "y" ]
then
  cd ${buildDirAbs} 
  bitbake -k core-image-minimal
fi

echo -e "${yellow}Yocto ${branch} for Altera-SoC is ready!${NC}"