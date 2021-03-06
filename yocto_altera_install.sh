#!/bi/sh - run in shell
#
# Building Yocto for Altera Cyclone5 Soc
# Usage: source yocto_altera_install

yellow='\E[1;33m'
NC='\033[0m'

echo -e "${yellow}Installing Yocto Rocko source for Altera-SoC...${NC}"
echo -e "${yellow}Enter main directory name...${NC}"
read mainDir
echo -e "${yellow}Downloading Yocto source...${NC}"
git clone -b rocko git://git.yoctoproject.org/poky.git ${mainDir}
cd ${mainDir}
echo -e "${yellow}Downloading meta-altera...${NC}"
git clone -b rocko git://github.com/kraj/meta-altera.git
echo -e "${yellow}Downloading meta-linaro...${NC}"
git clone -b rocko git://git.linaro.org/openembedded/meta-linaro.git

echo -e "${yellow}Setting up environment...${NC}"
echo -e "${yellow}Enter main directory name...${NC}"
read buildDir
source oe-init-build-env ${buildDir} #ToDo build directory from argument

echo -e "${yellow}Backup and edit local.conf...${NC}"
\cp conf/local.conf conf/local.conf.sample
\cp conf/bblayers.conf conf/bblayers.conf.sample
echo " " >> conf/local.conf #append to file
echo "#" >> conf/local.conf
echo "# Custom configuration" >> conf/local.conf
echo "#" >> conf/local.conf
echo "BB_NUMBER_THREADS = "'"6"'"" >> conf/local.conf
echo "PARALLEL_MAKE = "'"-j 8"'"" >> conf/local.conf
echo "DL_DIR = "'"${TOPDIR}/../downloads"'"" >> conf/local.conf
echo "SSTATE_DIR = "'"${TOPDIR}/../sstate-cache"'"" >> conf/local.conf

echo -e "${yellow}Patching Linaro Toolchain...${NC}"
echo "TARGET_CC_ARCH += "'"${LDFLAGS}"'"" >> ../meta-linaro/meta-linaro-toolchain/recipes-devtools/gcc/libgcc_linaro-5.2.bb

echo -e "${yellow}Creating custom BSP...${NC}"
cd ..
bitbake-layers create-layer cyclone-custom-bsp #ToDo layer directory from argument
cd meta-cyclone-custom-bsp

echo -e "${yellow}Creating custom target Machine...${NC}"
mkdir conf/machine
touch conf/machine/cyclone-custom-machine.conf
echo "#@TYPE: Machine" >> conf/machine/cyclone-custom-machine.conf
echo "#@NAME: Cyclone5 Custom Machine" >> conf/machine/cyclone-custom-machine.conf
echo "#@DESCRIPTION: Custom Machine configuration for the Cyclone V SoC" >> conf/machine/cyclone-custom-machine.conf
echo "#@MAINTAINER: Alex Sh" >> conf/machine/cyclone-custom-machine.conf
echo " " >> conf/machine/cyclone-custom-machine.conf
echo "require conf/machine/cyclone5.conf" >> conf/machine/cyclone-custom-machine.conf
echo "UBOOT_CONFIG = "'"de0-nano-soc"'"" >> conf/machine/cyclone-custom-machine.conf
echo "KERNEL_DEVICETREE = "'"socfpga_cyclone5_de0_sockit.dtb"'"" >> conf/machine/cyclone-custom-machine.conf
echo "UBOOT_EXTLINUX_FDT = "'"../socfpga_cyclone5_de0_sockit.dtb"'"" >> conf/machine/cyclone-custom-machine.conf

echo -e "${yellow}Configuring custom BSP...${NC}"
\cp conf/layer.conf conf/layer.conf.original
echo " " >> conf/layer.conf
echo "# Dependencies" >> conf/layer.conf
echo "LAYERDEPENDS_cyclone-custom-bsp = "'"meta-altera"'"" >> conf/layer.conf
echo "LAYERVERSION_cyclone-custom-bsp = "'"1"'"" >> conf/layer.conf
echo " " >> conf/layer.conf
echo "#" >> conf/layer.conf
echo "# Custom Altera-SoC configuration" >> conf/layer.conf
echo "#" >> conf/layer.conf
echo "PACKAGE_CLASSES = "'"package_ipk"'"" >> conf/layer.conf
echo "MACHINE = "'"cyclone-custom-machine"'"" >> conf/layer.conf
echo "PREFERRED_PROVIDER_virtual/kernel = "'"linux-altera-ltsi-rt"'"" >> conf/layer.conf
echo "PREFERRED_VERSION_linux-altera-ltsi-rt = "'"4.9%"'"" >> conf/layer.conf
echo "GCCVERSION = "'"linaro-5.2"'"" >> conf/layer.conf
echo "SDKGCCVERSION = "'"linaro-5.2"'"" >> conf/layer.conf
echo "DEFAULTTUNE = "'"cortexa9hf-neon"'"" >> conf/layer.conf

echo -e "${yellow}Adding layers...${NC}"
cd ~/poky/build
bitbake-layers add-layer ../meta-altera
bitbake-layers add-layer ../meta-linaro/meta-linaro-toolchain
bitbake-layers add-layer ../meta-cyclone-custom-bsp

echo -e "${yellow}Yocto Rocko source for Altera-SoC is ready!${NC}"
#echo -e "${yellow}Build U-Boot:${NC}!"
#echo -e "${yellow}bitbake -k virtual/bootloader${NC}!"
#echo -e "${yellow}Build Kernel:${NC}!"
#echo -e "${yellow}bitbake -k virtual/kernel${NC}!"

#echo -e "${yellow}Build Image:${NC}!"
#bitbake -k core-image-minimal
