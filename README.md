# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.
These will install nearly everything needed except the compilers themselves.
If something doesn't work, please let us know.
These scripts are intended to work on nearly any modern Linux, MacOS or Windows computer.

A minimal set of required tools is revealed by:

```sh
cmake -P scripts/requirements.cmake
```

Even if you can't install the packages above, try the external library build below.

## Build all Gemini3D external libraries

Pick a directory to install under, say $HOME/libgem:

```sh
cmake -P scripts/online_install.cmake -Dprefix=~/libgem
```

That installs files under ~/libgem/.

From Gemini3D, use those libraries like:

```sh
cmake -S gemini3d -B gemini3d/build -DCMAKE_PREFIX_PATH=~/libgem
```

## CMake update

If your CMake is too old (if you get an error message saying so), install a recent CMake version by:

```sh
cmake -P scripts/install_cmake.cmake
```

If that script doesn't work, try to build CMake:

```sh
cmake -P scripts/build_cmake.cmake
```

## Build specific libraries

To build a specific library after configuration, issue build command like:

```sh
cmake -Bbuild
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

## Offline packaging

Some computing environments can't easily use the internet.
To support these users, create an archive of all Gemini3D library software stack like:

```sh
cmake -Doutdir=~/mypkg -P scripts/package.cmake
```

Which creates several *.tar.bz2 source archives under ~/mypkg.
Then, the user would refer to these source archives like:

```sh
cmake -Bbuild -Dlocal=~/mypkg
```

The absolute paths are not encoded in the archives, so they can be easily copied among offline systems.
