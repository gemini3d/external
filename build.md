# Build specific libraries

By default this project builds all needed libraries.
Optionally, one can build specific libraries.
To build a specific library after configuration, issue CMake commands like:

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

### Build MUMPS

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/libgem

cmake --build build -t mumps
```

If MPI isn't available MPI will be build before MUMPS.
Also LAPACK and Scalapack are built before MUMPS.
