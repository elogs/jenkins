@ECHO OFF
set jenkinsIP=%1
set slaveIP=%2
set slaveUsr=%3
set slavePw=%4
set launcherSVNPath=%5
set wait=%6

PsExec.exe -u %slaveUsr% -p %slavePw% \\%slaveIP% /accepteula -i 2 -d cmd /C "svn co %launcherSVNPath% D:/slave_launcher"

echo "SVN checkout - done..."

PsExec.exe -u %slaveUsr% -p %slavePw% \\%slaveIP% /accepteula -i 2 -d cmd.exe /C D:/slave_launcher/kill_slave.bat

echo "Kill running Jenkins - done..."

PsExec.exe -u %slaveUsr% -p %slavePw% \\%slaveIP% /accepteula -i 2 -d cmd.exe /C D:/slave_launcher/generate_slave.bat %jenkinsIP% %slaveIP%

echo "Launch slave - done"

rem --- Sample command ---

rem slave_launcher.bat http://localhost:8080 10.69.243.14 user1 password123 svn://svnhost:5800/CI_Script/batch/ci_slave_launcher

sleep %wait%

exit