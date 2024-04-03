set PKG_CONFIG_PATH=%LIBRARY_PREFIX%\share\pkgconfig;%LIBRARY_PREFIX%\lib\pkgconfig;%PKG_CONFIG_PATH%

:: MSVC is preferred.
set CC=cl.exe
set CXX=cl.exe

if "%GZ_CLI_NAME_VARIANT%"=="origname" (
  set "CMAKE_ARGS=%CMAKE_ARGS% -DGZ_CLI_EXECUTABLE_NAME=gz"
)

if "%GZ_CLI_NAME_VARIANT%"=="gzcompatname" (
  set "CMAKE_ARGS=%CMAKE_ARGS% -DGZ_CLI_EXECUTABLE_NAME=gz11"
)

mkdir build
cd build
cmake %CMAKE_ARGS% ^
    -G "Ninja" ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True ^
    -DBoost_NO_BOOST_CMAKE=ON ^
    -DBoost_DEBUG=ON ^
    -DTBB_FOUND=1 ^
    -DTBB_INCLUDEDIR=%LIBRARY_PREFIX%\include ^
    -DTBB_LIBRARY_DIR=%LIBRARY_PREFIX%\lib ^
    -DUSE_EXTERNAL_TINY_PROCESS_LIBRARY=ON ^
    -DHAVE_OPENAL:BOOL=OFF ^
    -DUSE_EXTERNAL_TINYXML:BOOL=ON ^
    -DUSE_EXTERNAL_TINYXML2:BOOL=ON ^
    -DCMAKE_CXX_STANDARD=17 ^
    %SRC_DIR%
if errorlevel 1 exit 1

:: Build.
:: Reduced number of threads as a workaround for 
:: https://github.com/conda-forge/gazebo-feedstock/pull/185#issuecomment-1698933413
cmake --build . --config Release --parallel 1
if errorlevel 1 exit 1

:: Install.
cmake --build . --config Release --target install
if errorlevel 1 exit 1

:: Copy the [de]activate scripts to %PREFIX%\etc\conda\[de]activate.d.
:: This will allow them to be run on environment activation.
for %%F in (activate deactivate) DO (
    if not exist %PREFIX%\etc\conda\%%F.d mkdir %PREFIX%\etc\conda\%%F.d
    copy %RECIPE_DIR%\%%F.bat %PREFIX%\etc\conda\%%F.d\%PKG_NAME%_%%F.bat
)
