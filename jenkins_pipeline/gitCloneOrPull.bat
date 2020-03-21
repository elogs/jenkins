echo off
echo.
echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ++++ Cloning/Pulling latest from Project001
echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

set PATH=D:\CI\curl-7.54.0-win64-mingw\bin;%PATH%
set GIT_USER=you
set GIT_EMAIL=you@somecompany.com
set CI_GIT=D:\SOME_PATH\Project001
set CI_SCRIPT_BASE_URL=GIT_URL_WITHOUT_HTTP(S)_PREFIX/Project001
set IP_series=%NODE_NAME:~0,7%
set proxy=%PROXY_SERVER%

echo This is a %IP_series% machine
if %IP_series% == 10.xx.yy (
echo "Setting the proxy to %proxy%"
git config --global http.proxy %proxy%
)

git config --global user.email %GIT_EMAIL%
git config --global user.name %GIT_USER%

echo testing Gerrit connection...
curl -Is https://%CI_SCRIPT_BASE_URL% | head -1
if %ERRORLEVEL% == 0 (
set CI_SCRIPT_URL=https://%CI_SCRIPT_BASE_URL%
goto :start
)
curl -Is http://%CI_SCRIPT_BASE_URL% | head -1
if %ERRORLEVEL% == 0 (
set CI_SCRIPT_URL=http://%CI_SCRIPT_BASE_URL%
)

:start
echo [INFO] Will use %CI_SCRIPT_URL%
IF NOT EXIST %CI_GIT% (
echo [INFO] Creating %CI_GIT% dir...
MD %CI_GIT%
goto :clone
)

echo [INFO] Checking if %CI_GIT% is ok...
cd /D %CI_GIT%
git log -1
if not %ERRORLEVEL% == 0 (
echo [INFO] Repo is corrupted. Attempting to re-clone...
goto :clone
)
goto :proceed

:clone
rmdir /S /Q %CI_GIT%
git clone %CI_SCRIPT_URL% %CI_GIT% && (
  (echo [INFO] Creating backup of freshly cloned repo.
   rmdir /S /Q %CI_GIT%_bak
   xcopy %CI_GIT% %CI_GIT%_bak /S /I /Q /Y /F /H
   call )
) || (
  echo [WARNING] cloning failed - will use last clone backup
  IF NOT EXIST %CI_GIT%_bak (
    echo [FATAL] Failed retrieving backup. Try to manually execute the cloning process.
    echo [FATAL] Execute this command in TENV: git clone %CI_SCRIPT_URL% %CI_GIT%
    exit 1
  )
  xcopy %CI_GIT%_bak %CI_GIT% /S /I /Q /Y /F /H
  goto :done
)

:proceed
echo [INFO] Pulling latest from Gerrit.
cd /D %CI_GIT%

echo "branch -a"
git branch -a
echo "git clean -fd"
git clean -fd
echo "git reset --hard"
git reset --hard
git fetch --all
git checkout master
git pull origin master


if %ERRORLEVEL% == 1 (
echo [WARNING] Having issues with connecting to Gerrit. Unable to retrieve latest scripts, using what is available.
goto :done
)

:done
git log -3
if not %ERRORLEVEL% == 0 (
echo [FATAL] Something is not right. Try to manually execute the cloning process.
echo [FATAL] Execute this command in the slave: git clone %CI_SCRIPT_URL% %CI_GIT%
exit 1
)
exit 0
 
