# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.
These will install nearly everything needed except the compilers themselves.
If the MPI library is not available for your compiler, build MPI first under [scripts/mpi](./scripts/mpi).
If something doesn't work, please let us know.
These scripts are intended to work on nearly any modern Linux, MacOS or Windows computer.

On computers where admin/root is not available, simply proceed to the external library build below.
For computers with admin/root access, the prerequisite libraries are revealed by:

```sh
cmake -P scripts/requirements.cmake
```

For advanced use, individual libraries can be [built](./build.md).

The libraries installed by this package are referred to by other CMake project by specifying the CMake command line parameter `-DCMAKE_PREFIX_PATH=~/libgem` where ~/libgem is the arbitrary path to the libraries install location.

## Online: Build Gemini3D and external libraries

For computers where Internet is available, build Gemini3D and external libraries by:

```sh
cmake -P build-online.cmake
```

## Offline: Build Gemini3D and external libraries

For computers where Internet is not available, one must have a "gemini_package.tar" copied
to the computer that was previously created by the "package.cmake" script in this repo, as discussed at the bottom of this Readme.

```sh
cmake -E tar x /path/to/gemini_package.tar build-offline.cmake
# extracts build-offline.cmake to current directory, which is arbitrary

cmake -Dtarfile=/path/to/gemini_package.tar -P build-offline.cmake
# build Gemini3D and external libraries without Internet, installing to ~/libgem by default
```

## Development: local source directory(ies)

For development, one can specify a local source directory(ies) to build from like:

```sh
cmake -Dglow_source=/path/to/my_glow_code ...
```

That assumes the glow source directory that you're making changes is at the path specified.
Git/downloading is not used for that library.
The libraries this work for include:

```
ffilesystem iniparser glow hwm14 msis lapack scalapack mumps libsc p4est forestclaw
```

In general to speed build time, optionally build just that library (and its prereqs) like:

```sh
cmake --build build -t glow
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

The end-user on the offline computer would use this gemini_package.tar as follows.
This command can be executed from any directory, the build will take place under the directory where the gemini_package.tar file is located.
In this example below for /path/to/gemini_package.tar the build directory would be /path/to/external/ and /path/to/gemini3d/

```sh
tar
cmake -Dprefix=$HOME/libgem -Dtarfile=/path/to/gemini_package.tar -P build-offline.cmake
```
