# 环境需求
* Mac OS X 10.9+, Xcode 10+
* Windows 7+, Visual Studio 2019
* Python 3.5+
* Android: NDK r20+, Android Studio 3.4+
* Cmake 3.16+ (In Android Studio's cmake plugin 3.6+)

# 编译 Mac

```
mkdir build_mac
cd build_mac
cmake .. -GXcode
open test.xcodeproj

```

# 编译 Win32

```
mkdir build_win32
cd build_win32
cmake .. -G"Visual Studio 16 2019" -A Win32
cmake --build .

```