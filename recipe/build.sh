if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
  (
    mkdir -p build-host
    pushd build-host

    export CC=$CC_FOR_BUILD
    export CXX=$CXX_FOR_BUILD
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
    export PKG_CONFIG_PATH=${PKG_CONFIG_PATH//$PREFIX/$BUILD_PREFIX}

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CXXFLAGS

    cmake .. \
      -G "Ninja" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$BUILD_PREFIX -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
      -DDCMAKE_CXX_STANDARD=17

    # No need to compile everything, just gazebomsgs_out is sufficient
    cmake --build . --target gazebomsgs_out --parallel ${CPU_COUNT} --config Release
  )
fi


mkdir build
cd build

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DFREEIMAGE_RUNS:BOOL=ON -DFREEIMAGE_RUNS__TRYRUN_OUTPUT:STRING="" -DFREEIMAGE_COMPILES:BOOL=ON -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DPROTOBUF_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DGAZEBOMSGS_OUT_EXECUTABLE:STRING=`pwd`/../build-host/gazebo/msgs/gazebomsgs_out"
fi

if [[ "${GZ_CLI_NAME_VARIANT}" == "origname" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DGZ_CLI_EXECUTABLE_NAME=gz"
fi

if [[ "${GZ_CLI_NAME_VARIANT}" == "gzcompatname" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DGZ_CLI_EXECUTABLE_NAME=gz11"
fi


cmake ${CMAKE_ARGS} .. \
      -G "Ninja" \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBoost_NO_BOOST_CMAKE=OFF \
      -DBoost_DEBUG=OFF \
      -DHAVE_OPENAL:BOOL=OFF

cmake --build . --config Release -- -j$CPU_COUNT
cmake --build . --config Release --target install

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

if [[ "${GZ_CLI_NAME_VARIANT}" == "origname" ]]; then
  cp $PREFIX/bin/gz $PREFIX/bin/gz11
fi

# Ensure that plugins are found as libraries linked by the linker
# in macos, see
# https://github.com/RoboStack/ros-noetic/issues/228
# https://github.com/RoboStack/ros-noetic/issues/462
# https://github.com/RoboStack/ros-humble/issues/185
# We do not symlink all the libraries as they do not have Gazebo-specific
# prefix, so we prefer to minimize the risk of clobbering, so we only symlink
# the one used in https://github.com/ros-simulation/gazebo_ros_pkgs/blob/f9e1a4607842afa5888ef01de31cd64a1e3e297f/gazebo_plugins/CMakeLists.txt
if [[ "${target_platform}" == osx-* ]]; then
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libCameraPlugin.dylib $CONDA_PREFIX/lib/libCameraPlugin.dylib
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libElevatorPlugin.dylib $CONDA_PREFIX/lib/libElevatorPlugin.dylib
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libMultiCameraPlugin.dylib $CONDA_PREFIX/lib/libMultiCameraPlugin.dylib
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libDepthCameraPlugin.dylib $CONDA_PREFIX/lib/libDepthCameraPlugin.dylib
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libGpuRayPlugin.dylib $CONDA_PREFIX/lib/libGpuRayPlugin.dylib
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libHarnessPlugin.dylib $CONDA_PREFIX/lib/libHarnessPlugin.dylib
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libWheelSlipPlugin.dylib $CONDA_PREFIX/lib/libWheelSlipPlugin.dylib
    ln -s $CONDA_PREFIX/lib/gazebo-11/plugins/libRayPlugin.dylib $CONDA_PREFIX/lib/libRayPlugin.dylib
fi
