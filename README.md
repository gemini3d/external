# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.
These will install nearly everything needed except the compilers themselves.
If something doesn't work, please let us know.
These scripts are intended to work on nearly any Linux, MacOS or Windows computer.

## CMake build system

If your CMake is too old, install a recent CMake version by:

```sh
cmake -P scripts/install_cmake.cmake
```

If that script doesn't work, try to build CMake:

```sh
cmake -P scripts/build_cmake.cmake
```

## Essential build tools

There are a minimal set of compilers and tools useful to build scientific programs in general.
If you have "sudo" / admin access, you can install them with:

```sh
cmake -P scripts/requirements.cmake
```

If you don't have permission to install these programs, try the external library build below anyway.
If something is missing that stops the build, try asking your system administrator and/or us.

## Build all Gemini3D external libraries

Pick a directory to install under, say $HOME/libgem:

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/libgem

cmake --build build
```

That installs files under ~/libgem/[lib,include,bin] and similar.

From Gemini3D, use those libraries like:

```sh
cd ~/code/gemini3d

cmake -B build -DCMAKE_PREFIX_PATH=~/libgem

cmake --build build
```

## Build specific libraries

To build a specific library after configuration, issue build command like:

```sh
cmake --build build -t <library>
```

The prerequisites of the library will also be built.

### Python

If a new enough Python isn't available on your system, you can build Python via project
[cmake-python-build](https://github.com/gemini3d/cmake-python-build).

### Build OpenMPI

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/libgem -Dopenmpi=yes

cmake --build build -t mpi
```

### Build MPICH

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/libgem -Dmpich=yes

cmake --build build -t mpi
```

### Build Scalapack

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/libgem

cmake --build build -t mumps
```

If MPI isn't available MPI will be build before MUMPS.
Also LAPACK and Scalapack are built before MUMPS.
