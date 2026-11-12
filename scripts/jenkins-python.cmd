@echo off
setlocal
rem PYTHON_EXE must be an executable path, without surrounding quotes or arguments.
if defined PYTHON_EXE goto configured
python -c "import sys; assert sys.version_info >= (3, 10)" >nul 2>&1
if not errorlevel 1 goto python
py -3 -c "import sys; assert sys.version_info >= (3, 10)" >nul 2>&1
if not errorlevel 1 goto launcher
if exist "%ProgramFiles%\Python313\python.exe" (
    set "PYTHON_EXE=%ProgramFiles%\Python313\python.exe"
    goto configured
)
>&2 echo ERROR: Jenkins agent cannot find Python 3.10+.
>&2 echo Install Python for all users, or set the Jenkins node environment variable PYTHON_EXE to its absolute python.exe path.
>&2 echo The Jenkins service account must have permission to run that executable.
exit /b 1
:configured
"%PYTHON_EXE%" -c "import sys; assert sys.version_info >= (3, 10)" >nul 2>&1
if errorlevel 1 (
    >&2 echo ERROR: PYTHON_EXE is inaccessible or is not Python 3.10+.
    exit /b 1
)
"%PYTHON_EXE%" %*
exit /b %errorlevel%
:python
python %*
exit /b %errorlevel%
:launcher
py -3 %*
exit /b %errorlevel%
