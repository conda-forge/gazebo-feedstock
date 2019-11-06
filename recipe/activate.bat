@if not defined CONDA_PREFIX goto:eof

@call "%CONDA_PREFIX%\Library\share\gazebo\setup.bat"
