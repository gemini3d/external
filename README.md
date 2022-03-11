# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.
These will install nearly everything needed except the compilers themselves.
If something doesn't work, please let us know.
These scripts are intended to work on nearly any Linux, MacOS or Windows computer.

## CMake and essential build tools

Since CMake controls all aspects of our programs and external libraries, we first install a recent version of CMake.

```sh
cmake -P scripts/install_cmake.cmake
```

If that script doesn't work, try to build CMake:

```sh
cmake -P scripts/build_cmake.cmake
```

There are a minimal set of compilers and tools useful to build scientific programs in general, which are installed by:

```sh
cmake -P scripts/requirements.cmake
```

If you have problems installing CMake or the requirements.cmake programs, please let us know.

## Build all Gemini3D external libraries

Pick a directory to install under, say $HOME/gemini_libs:

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/gemini_libs

cmake --build build
```

That installs files under ~/gemini_libs/[lib,include,bin] and similar.

From Gemini3D, use those libraries like:

```sh
cd ~/code/gemini3d

cmake -B build -DCMAKE_PREFIX_PATH=~/gemini_libs

cmake --build build
```

## Build specific libraries

This is for **advanced users**.
Typical users let the program build everything it needs.

To build a specific library after configuration, issue build command like:

```sh
cmake --build build -t <library>
```

The prerequisites of the library will also be built.

### Build OpenMPI

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/gemini_libs -Dopenmpi=yes

cmake --build build -t mpi
```

That builds HWLOC and then OpenMPI.

### Build MPICH

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/gemini_libs -Dmpich=yes

cmake --build build -t mpi
```

That builds HWLOC and then MPICH

### Build Scalapack

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/gemini_libs

cmake --build build -t mumps
```

If MPI isn't available MPI will be build before MUMPS.
Also LAPACK and Scalapack are built before MUMPS.
