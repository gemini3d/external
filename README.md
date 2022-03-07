# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.

The most common task is to install a recent version of CMake:

```sh
cmake -P scripts/install_cmake.cmake
```

If that script doesn't work, try to build CMake:

```sh
cmake -P scripts/build_cmake.cmake
```

## Autotools

Several packages use Autotools, and need Autotools installed beforehand.
Example command to install Autotools:

```sh
[apt,brew,zypper] install autoconf automake libtool
```

## Build all Gemini3D external libraries

To save time, MPI isn't built unless requested with `cmake -Dbuild_all=yes` option added to below.

Pick a directory to install under, say $HOME/gemini_libs:

```sh
cmake -B build --install-prefix=$HOME/gemini_libs

cmake --build build
```

That installs files under $HOME/gemini_libs/[lib,include,bin] and similar.

From Gemini3D, use those libraries like:

```sh
cd ~/code/gemini3d

cmake -B build -DCMAKE_PREFIX_PATH=$HOME/gemini_libs

cmake --build build
```

## Build specific libraries

To build a specific library after configuration, issue build command like:

```sh
cmake --build build --target <library>
```

The prerequisites of the library will also be built.

### Build OpenMPI

```sh
cmake -B build --install-prefix=$HOME/gemini_libs -Dopenmpi=yes

cmake --build build --target mpi
```

That builds HWLOC and then OpenMPI.

### Build MPICH

```sh
cmake -B build --install-prefix=$HOME/gemini_libs -Dmpich=yes

cmake --build build --target mpi
```

That builds HWLOC and then MPICH

### Build Scalapack

```sh
cmake -B build --install-prefix=$HOME/gemini_libs

cmake --build build --target scalapack
```

If MPI wasn't already available, MPI will be build before Scalapack.
Also LAPACK will be built before Scalapack.
