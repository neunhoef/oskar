$ErrorActionPreference="Stop"
$DEPS_DIR = "C:\iResearch"
############################################################################
# Install Boost
############################################################################
$BOOST_DIR = "$DEPS_DIR\boost"
$BOOST_ROOT = "$BOOST_DIR\boost_1_64_0"
$BOOST_VERSION = "1.64.0"
$BOOST_SRC_FILE= "boost_1_64_0.zip"
$BOOST_URL = "https://netcologne.dl.sourceforge.net/project/boost/boost/$BOOST_VERSION/$BOOST_SRC_FILE"
if(!(Test-Path -Path "$BOOST_ROOT/boost/version.hpp")) {
	Remove-Item -Recurse -Force -ErrorAction Ignore "$BOOST_ROOT"
}
if(!(Test-Path -Path "$BOOST_ROOT")) {
	Write-Output "New-Item -ItemType Directory -Force -Path $BOOST_DIR"
	New-Item -ItemType Directory -Force -Path "$BOOST_DIR"
	Write-Output "cd $BOOST_DIR"
	cd "$BOOST_DIR"
	Write-Output "Invoke-WebRequest $BOOST_URL -OutFile $BOOST_SRC_FILE"
	Invoke-WebRequest "$BOOST_URL" -OutFile "$BOOST_SRC_FILE"
	Write-Output "Expand-Archive $BOOST_SRC_FILE -DestinationPath $BOOST_DIR"
	Expand-Archive "$BOOST_SRC_FILE" -DestinationPath "$BOOST_DIR"
	Write-Output "cd $BOOST_ROOT"
	cd "$BOOST_ROOT"
	Write-Output "bootstrap.bat --with-libraries=test"
	cmd.exe /c 'bootstrap.bat --with-libraries=test'
	Write-Output "bootstrap.bat --with-libraries=thread"
	cmd.exe /c 'bootstrap.bat --with-libraries=thread'
	Write-Output "b2 --build-type=complete stage address-model=64"
	cmd.exe /c 'b2 --build-type=complete stage address-model=64'
}
############################################################################
# Install Depends
# Depends used to determine missing DLLs when $LastExitCode == -1073741515
# Usage: http://www.dependencywalker.com/help/html/hidr_command_line_help.htm
# depends.exe /c /ot:<text dump file> <app> <args>...
# depends.exe /c /of:<formated dump file> <app> <args>...
# depends.exe /c /ot:<csv dump file> <app> <args>...
# Get-Content -Path <text dump file>
# Get-Content -Path <formated dump file>
# Get-Content -Path <csv dump file>
############################################################################
$DEPENDS_DIR = "$DEPS_DIR\depends"
$DEPENDS_ROOT = "$DEPENDS_DIR\2.2"
$DEPENDS_VERSION = "2.2"
$DEPENDS_SRC_FILE = "depends22_x64.zip"
$DEPENDS_URL = "http://www.dependencywalker.com/$DEPENDS_SRC_FILE"
if(!(Test-Path -Path "$DEPENDS_ROOT")) {
	Write-Output "New-Item -ItemType Directory -Force -Path $DEPENDS_DIR"
	New-Item -ItemType Directory -Force -Path "$DEPENDS_DIR"
	Write-Output "cd $DEPENDS_DIR"
	cd "$DEPENDS_DIR"
	Write-Output "Invoke-WebRequest $DEPENDS_URL -OutFile $DEPENDS_SRC_FILE"
	Invoke-WebRequest "$DEPENDS_URL" -OutFile "$DEPENDS_SRC_FILE"
	Write-Output "New-Item -ItemType Directory -Force -Path $DEPENDS_ROOT"
	New-Item -ItemType Directory -Force -Path "$DEPENDS_ROOT"
	Write-Output "Expand-Archive "$DEPENDS_SRC_FILE" -DestinationPath $DEPENDS_ROOT"
	Expand-Archive "$DEPENDS_SRC_FILE" -DestinationPath "$DEPENDS_ROOT"
}
############################################################################
# Install ICU
############################################################################
$ICU_DIR = "$DEPS_DIR\icu"
$ICU_ROOT = "$ICU_DIR\icu"
$ICU_VERSION = "57.1"
$ICU_SRC_FILE = "icu4c-57_1-Win64-msvc10.zip"
$ICU_URL = "https://kent.dl.sourceforge.net/project/icu/ICU4C/$ICU_VERSION/$ICU_SRC_FILE"
if(!(Test-Path -Path "$ICU_ROOT/include/unicode/uversion.h")) {
	Remove-Item -Recurse -Force -ErrorAction Ignore "$ICU_ROOT"
}
if(!(Test-Path -Path "$ICU_ROOT")) {
	Write-Output "New-Item -ItemType Directory -Force -Path $ICU_DIR"
	New-Item -ItemType Directory -Force -Path "$ICU_DIR"
	Write-Output "cd $ICU_DIR"
	cd "$ICU_DIR"
	Write-Output "Invoke-WebRequest $ICU_URL -OutFile $ICU_SRC_FILE"
	Invoke-WebRequest "$ICU_URL" -OutFile "$ICU_SRC_FILE"
	Write-Output "Expand-Archive $ICU_SRC_FILE -DestinationPath $ICU_DIR"
	Expand-Archive "$ICU_SRC_FILE" -DestinationPath "$ICU_DIR"
}
############################################################################
# Install Lz4
############################################################################  
$LZ4_DIR = "$DEPS_DIR\lz4"
$LZ4_ROOT = "$LZ4_DIR\1.7.5"
$LZ4_VERSION = "1.7.5"
$LZ4_SRC_FILE = "v$LZ4_VERSION.zip"
$LZ4_URL = "https://github.com/lz4/lz4/archive/$LZ4_SRC_FILE"
if(!(Test-Path -Path "$LZ4_ROOT/debug/include/lz4.h") -Or !(Test-Path -Path "$LZ4_ROOT/release/include/lz4.h")) {
	Remove-Item -Recurse -Force -ErrorAction Ignore "$LZ4_DIR"
}
if(!(Test-Path -Path "$LZ4_ROOT")) {
	Write-Output "New-Item -ItemType Directory -Force -Path $LZ4_DIR"
	New-Item -ItemType Directory -Force -Path "$LZ4_DIR"
	Write-Output "Remove-Item -Recurse -Force $LZ4_DIR\lz4-$LZ4_VERSION"
	if (Test-Path "$LZ4_DIR\lz4-$LZ4_VERSION") { Remove-Item -Recurse -Force "$LZ4_DIR\lz4-$LZ4_VERSION" }
	Write-Output "cd $LZ4_DIR"
	cd "$LZ4_DIR"
	Write-Output "Invoke-WebRequest $LZ4_URL -OutFile $LZ4_SRC_FILE"
	Invoke-WebRequest "$LZ4_URL" -OutFile "$LZ4_SRC_FILE"
	Write-Output "Expand-Archive $LZ4_SRC_FILE -DestinationPath $LZ4_DIR"
	Expand-Archive "$LZ4_SRC_FILE" -DestinationPath "$LZ4_DIR"
	cd "$LZ4_DIR\lz4-$LZ4_VERSION"
	Write-Output "New-Item -ItemType Directory -Force -Path build\debug"
	New-Item -ItemType Directory -Force -Path "build\debug"
	Write-Output "New-Item -ItemType Directory -Force -Path build\release"
	New-Item -ItemType Directory -Force -Path "build\release"
	cd "$LZ4_DIR\lz4-$LZ4_VERSION\build\debug"
	cmake "-DCMAKE_INSTALL_PREFIX=$LZ4_ROOT/debug" -DBUILD_STATIC_LIBS=on -g "Visual Studio 2015" -Ax64 ../../contrib/cmake_unofficial
	cmake --build . --config Debug
	cd "$LZ4_DIR\lz4-$LZ4_VERSION\build\release"
	cmake "-DCMAKE_INSTALL_PREFIX=$LZ4_ROOT/release" -DBUILD_STATIC_LIBS=on -g "Visual Studio 2015" -Ax64 ../../contrib/cmake_unofficial
	cmake --build . --config Release
	cd "$LZ4_DIR\lz4-$LZ4_VERSION\build\debug"
	Write-Output "New-Item -ItemType Directory -Force -Path $LZ4_ROOT/debug"
	New-Item -ItemType Directory -Force -Path "$LZ4_ROOT/debug"
	cmake --build . --target install
	cd "$LZ4_DIR\lz4-$LZ4_VERSION\build\release"
	Write-Output "New-Item -ItemType Directory -Force -Path $LZ4_ROOT/release"
	New-Item -ItemType Directory -Force -Path "$LZ4_ROOT/release"
	cmake --build . --target install
}
############################################################################
# Install snowball
############################################################################
$ErrorActionPreference="Stop"
$DEPS_DIR = "$pwd\..\iresearch.deps"
$SNOWBALL_DIR = "$DEPS_DIR\snowball"
$SNOWBALL_ROOT = "$SNOWBALL_DIR\build"
$SNOWBALL_URL = "https://github.com/snowballstem/snowball.git"
if(!(Test-Path -Path "$SNOWBALL_DIR/include/libstemmer.h")) {
	Remove-Item -Recurse -Force -ErrorAction Ignore "$SNOWBALL_DIR"
}
if(!(Test-Path -Path "$SNOWBALL_ROOT")) {
	Write-Output "New-Item -ItemType Directory -Force -Path $SNOWBALL_DIR"
	New-Item -ItemType Directory -Force -Path "$SNOWBALL_DIR"
	Write-Output "Remove-Item -Recurse -Force $DEPS_DIR\snowball"
	if (Test-Path "$DEPS_DIR\snowball") { Remove-Item -Recurse -Force "$DEPS_DIR\snowball" }
	Write-Output "cd $DEPS_DIR"
	cd "$DEPS_DIR"
	Write-Output "git clone --quiet $SNOWBALL_URL snowball"
	git clone --quiet "$SNOWBALL_URL" snowball
	Write-Output "cd $SNOWBALL_DIR"
	cd "$SNOWBALL_DIR"
	git reset --hard 5137019d68befd633ce8b1cd48065f41e77ed43e
	Write-Output "New-Item -ItemType Directory -Force -Path $SNOWBALL_ROOT"
	New-Item -ItemType Directory -Force -Path "$SNOWBALL_ROOT"
}
############################################################################
# Install gtest
############################################################################
$GTEST_DIR = "$DEPS_DIR\gtest"
$GTEST_ROOT = "$GTEST_DIR\build"
$GTEST_URL = "https://github.com/google/googletest.git"
if(!(Test-Path -Path "$GTEST_DIR/googletest/include/gtest/gtest.h")) {
	Remove-Item -Recurse -Force -ErrorAction Ignore "$GTEST_DIR"
}
if(!(Test-Path -Path "$GTEST_ROOT")) {
	Write-Output "New-Item -ItemType Directory -Force -Path $GTEST_DIR"
	New-Item -ItemType Directory -Force -Path "$GTEST_DIR"
	Write-Output "cd $DEPS_DIR"
	cd "$DEPS_DIR"
	Write-Output "git clone --depth 1 --recursive --quiet $GTEST_URL gtest"
	git clone --depth 1 --recursive --quiet "$GTEST_URL" gtest
	Write-Output "cd $GTEST_DIR"
	cd "$GTEST_DIR"
	Write-Output "New-Item -ItemType Directory -Force -Path build"
	New-Item -ItemType Directory -Force -Path "build"
	Write-Output "cd $GTEST_ROOT"
	cd "$GTEST_ROOT"
	cmake -Dgtest_force_shared_crt=ON -DBUILD_GTEST=ON -DBUILD_GMOCK=OFF -g "Visual Studio 2015" -Ax64 ..
	cmake --build . --config Debug
	cmake --build . --config Release
	Copy-Item -Path "$GTEST_DIR\googletest\include" -Recurse -Destination "$GTEST_ROOT\googletest\Debug"
	Copy-Item -Path "$GTEST_DIR\googletest\include" -Recurse -Destination "$GTEST_ROOT\googletest\Release"

	# FindGTest.cmake expects debug libraries to be named without the 'd' suffix
	Copy-Item -Path "$GTEST_ROOT\googletest\Debug\gtestd.lib" -Recurse -Destination "$GTEST_ROOT\googletest\Debug\gtest.lib"
	Copy-Item -Path "$GTEST_ROOT\googletest\Debug\gtest_maind.lib" -Recurse -Destination "$GTEST_ROOT\googletest\Debug\gtest_main.lib"
}
############################################################################
# Go back to the root of the project and setup the build directory
############################################################################
$env:BOOST_ROOT = $BOOST_ROOT -replace '\\','/'
$env:GTEST_ROOT = "$GTEST_ROOT\googletest\Debug" -replace '\\','/'
$env:ICU_ROOT = $ICU_ROOT -replace '\\','/'
$env:LZ4_ROOT = "$LZ4_ROOT\debug" -replace '\\','/'
$env:SNOWBALL_ROOT = "$SNOWBALL_DIR" -replace '\\','/'
$env:PATH += ";$DEPENDS_ROOT"

New-Item -ItemType Directory -Force -Path "$DEPS_DIR\build"
cd "$DEPS_DIR\build"
cmake -g "Visual Studio 2017" -Ax64 -DCMAKE_BUILD_TYPE=Debug -DMSVC_BUILD_THREADS=8 -DUSE_TESTS=On ..
cmake --build . --config Debug --target iresearch-tests

Write-Output "cd $DEPS_DIR\build\bin\Debug"
cd "$DEPS_DIR\build\bin\Debug"
Write-Output "cmd.exe /c ""$DEPS_DIR\build\bin\Debug\iresearch-tests.exe"" ""--ires_output"" ""--ires_output_path=$env:TEMP"" ""--gtest_repeat=10"""
cmd.exe /c """$DEPS_DIR\build\bin\Debug\iresearch-tests.exe"" ""--ires_output"" ""--ires_output_path=$env:TEMP"" ""--gtest_repeat=10"" ""--ires_log_level=ERROR"" 2>&1"