# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.
These will install nearly everything needed except the compilers themselves.
If something doesn't work, please let us know.
These scripts are intended to work on nearly any modern Linux, MacOS or Windows computer.


On computers where admin/root is not available, simply proceed to the external library build below.
For computers with admin/root access, the prerequisite libraries are revealed by:

```sh
cmake -P scripts/requirements.cmake
```

For advanced use, individual libraries can be [built](./build.md).

## Build all Gemini3D external libraries

Pick a directory to install under, say ~/libgem:

```sh
cmake -P scripts/online_install.cmake -Dprefix=~/libgem
```

That installs files under ~/libgem/.

From Gemini3D, use those libraries like:

```sh
cmake -S gemini3d -B gemini3d/build -DCMAKE_PREFIX_PATH=~/libgem
```

## CMake update

If you get an error message stating CMake is too old, install a recent CMake version by:

```sh
cmake -P scripts/install_cmake.cmake
```

If that script doesn't work, try to build CMake:

```sh
cmake -P scripts/build_cmake.cmake
```

## Offline packaging

Some computing environments can't easily use the internet.
To support these users, create an archive of all Gemini3D library software stack like:

```sh
cmake -P scripts/package.cmake
```

Which creates a "gemini_package.tar" containing all the source code used by this project and external libraries.
Then, the user would refer to these source archives like:

```sh
cmake -Bbuild -Dlocal=~/mypkg
```
