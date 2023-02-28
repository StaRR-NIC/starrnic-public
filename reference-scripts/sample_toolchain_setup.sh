source /opt/xilinx/xrt/setup.sh
export PLATFORM_REPO_PATHS=/opt/xilinx/platforms

if [[ -n $MY_VITIS_VERSION ]]; then
    export MY_VITIS_VERSION=$MY_VITIS_VERSION
else
    export MY_VITIS_VERSION="2021.2"
fi

export MY_VITIS_INSTALL_PATH="/tools/Xilinx"
export XILINXD_LICENSE_FILE="port@license-server-ip"

if [[ -f "$MY_VITIS_INSTALL_PATH/Vitis/$MY_VITIS_VERSION/settings64.sh" ]]; then
    export PLATFORM_REPO_PATHS=$PLATFORM_REPO_PATHS:$MY_VITIS_INSTALL_PATH/Vitis/$MY_VITIS_VERSION/platforms
    source $MY_VITIS_INSTALL_PATH/Vitis/$MY_VITIS_VERSION/settings64.sh

    # Needed in Centos (verify if needed in Ubuntu), keeping for now
    export LD_LIBRARY_PATH=$XILINX_VITIS/lib/lnx64.o/Default/:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$XILINX_VITIS/lib/lnx64.o/:$LD_LIBRARY_PATH
    # Needed in Ubuntu
    export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
fi

export MODELSIM_PATH=""
if [[ -d $HOME/opt/modelsim ]]; then
    export MODELSIM_PATH=$HOME/opt/modelsim
fi
if [[ -d /opt/modelsim ]]; then
    export MODELSIM_PATH=/opt/modelsim
fi

export PATH=$MODELSIM_PATH/modelsim-se_2020.1/modeltech/linux_x86_64:$PATH
export LM_LICENSE_FILE=$MODELSIM_PATH/../modelsim_license.dat:$LM_LICENSE_FILE