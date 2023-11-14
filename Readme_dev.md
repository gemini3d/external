# Build specific libraries

By default this project builds all needed libraries.

For computers with admin/root access, the prerequisite libraries are revealed by:

```sh
cmake -P scripts/requirements.cmake
```

Optionally, one can build specific libraries.
To build a specific library after configuration, issue CMake commands like:

```sh
cmake -Bbuild
cmake --build build -t <library>
```

The prerequisites of the library will also be built.

## Python

If a new enough Python isn't available on your system, you can build Python via project
[cmake-python-build](https://github.com/gemini3d/cmake-python-build).

## Build MUMPS

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=~/libgem

cmake --build build -t mumps
```

If MPI isn't available MPI will be build before MUMPS.
Also LAPACK and Scalapack are built before MUMPS.

## Development: local source directory(ies)

The options for this project are typically contained in [options.cmake](./options.cmake).

For development, one can specify a local source directory(ies) to build from like:

```sh
cmake -Dglow_source=/path/to/my_glow_code ...
```

That assumes the glow source directory that you're making changes is at the path specified.
Git/downloading is not used for that library.
The libraries this work for include:

```
ffilesystem glow hwm14 msis lapack scalapack mumps
```

In general to speed build time, optionally build just that library (and its prereqs) like:

```sh
cmake --build build -t glow
```
