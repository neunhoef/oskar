call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd" -arch=x64
call :cleanup
set installdir="C:\OpenSSL-ArangoDB\2017\shared-release" && perl Configure shared --release --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || cd ..
call :cleanup
set installdir="C:\OpenSSL-ArangoDB\2017\static-release" && perl  Configure no-dynamic-engine no-shared --release --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || cd ..
call :cleanup
set installdir="C:\OpenSSL-ArangoDB\2017\static-debug" && perl  Configure no-shared --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || cd ..
call :cleanup
set installdir="C:\OpenSSL-ArangoDB\2017\shared-debug" && perl  Configure shared --prefix="%installdir%" --openssldir="%installdir%\ssl" VC-WIN64A && echo "##### conf ok" && nmake && echo "##### make ok" && nmake install && echo "##### install ok" || cd ..

:cleanup
cd C:\openssl_repo
git fetch
git reset --hard OpenSSL_1_1_0h
git clean -f -d -x