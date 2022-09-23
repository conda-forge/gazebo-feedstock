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
      -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True

    # No need to compile everything, just gazebomsgs_out is sufficient
    cmake --build . --target gazebomsgs_out --parallel ${CPU_COUNT} --config Release
  )
fi


mkdir build
cd build

# Workaround for https://github.com/conda-forge/gazebo-feedstock/pull/150
# Remove when boost is updated to 1.80.0
if [[ "${target_platform}" == "osx-64" ]]; then
  export CXXFLAGS="-DBOOST_ASIO_DISABLE_STD_ALIGNED_ALLOC ${CXXFLAGS}"
fi

# See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
if [[ "${target_platform}" == "osx-64" ]]; then
  export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi


if [[ "${CONDA_BUILD_CROSS_COMPILATION}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DFREEIMAGE_RUNS:BOOL=ON -DFREEIMAGE_RUNS__TRYRUN_OUTPUT:STRING="" -DFREEIMAGE_COMPILES:BOOL=ON -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DGAZEBOMSGS_OUT_EXECUTABLE:STRING=`pwd`/../build-host/gazebo/msgs/gazebomsgs_out"
fi

cmake ${CMAKE_ARGS} .. \
      -G "Ninja" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBoost_NO_BOOST_CMAKE=OFF \
      -DBoost_DEBUG=OFF \
      -DHAVE_OPENAL:BOOL=OFF

cmake --build . --config Release -- -j$CPU_COUNT
cmake --build . --config Release --target install

# Regression test for https://github.com/conda-forge/gazebo-feedstock/issues/148
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  cmake ${CMAKE_ARGS} -DBUILD_TESTING:BOOL=ON .
  ninja INTEGRATION_transport_msg_count 
  ctest --output-on-failure -C Release -R INTEGRATION_transport_msg_count
fi

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done
