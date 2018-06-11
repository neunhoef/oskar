if exist "C:\Windows\Temp\openssl" rmdir /s /q "C:\Windows\Temp\openssl"
git clone -b "OpenSSL_1_1_0h" https://github.com/openssl/openssl C:\Windows\Temp\openssl
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd" -arch=x64
call :cleanup
set installdir=C:\OpenSSL-ArangoDB\2017\shared-release
perl Configure shared --release --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || pause
call :cleanup
set installdir=C:\OpenSSL-ArangoDB\2017\static-release
perl  Configure no-shared --release --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || pause
call :cleanup
set installdir=C:\OpenSSL-ArangoDB\2017\static-debug
perl  Configure no-shared --debug --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || pause
call :cleanup
set installdir=C:\OpenSSL-ArangoDB\2017\shared-debug
perl  Configure shared --debug --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || pause
wget "https://raw.githubusercontent.com/neunhoef/oskar/master/installer/windows/CMD/FindOpenSSL.cmake" -O "%~dp0\FindOpenSSL.cmake"
copy "%~dp0\FindOpenSSL.cmake" "C:\OpenSSL-ArangoDB\FindOpenSSL.cmake"
if exist "C:\Windows\Temp\openssl" rmdir /s /q "C:\Windows\Temp\openssl"

:cleanup
cd C:\Windows\Temp\openssl
git fetch
git reset --hard OpenSSL_1_1_0h
git clean -f -d -x