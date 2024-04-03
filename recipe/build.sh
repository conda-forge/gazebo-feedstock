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
