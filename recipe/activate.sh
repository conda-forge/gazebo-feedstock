source "${CONDA_PREFIX}/share/gazebo/setup.sh"

_UNAME=`uname -s`
if [ "$_UNAME" = "Darwin" ]; then
  export DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${GAZEBO_PLUGIN_PATH}
fi
unset _UNAME
