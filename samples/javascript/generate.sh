rm -rf build
mkdir -p build
cd build
wasimake cmake -DCMAKE_BUILD_TYPE=RELEASE --config Release ..
cd ..
./build.sh