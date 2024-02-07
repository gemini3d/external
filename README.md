# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.
These will install everything needed except the compilers themselves.
These scripts are intended to work on nearly any modern Linux, MacOS or Windows computer.

Try to build this repo:

```sh
git clone https://github.com/gemini3d/external
```

A one-step convenience script:

```sh
cmake -P build-online.cmake
```

or, to use CMake traditionally:

```sh
cmake -B build

cmake --build build

cmake --install build
```

## MPI

If you are having trouble, run the MPI-3 test script by itself and then open a GitHub issue or
contact the Gemini3D development team.

```sh
cmake -P check-mpi3.cmake
```

If desired, one can build OpenMPI themselves, but this is rarely necessary:

```sh
cmake -P scripts/build_openmpi.cmake
```

then try to build this repo again.

If your CMake version is too old (indicated by CMake error message saying so), [update CMake](./Readme_cmake.md), then try to build this repo again.

The libraries installed by this package are referred to by other CMake project by specifying the CMake command line parameter `-DCMAKE_PREFIX_PATH=~/libgem` where ~/libgem is the arbitrary path to the libraries install location.

---

Reference: [Advanced users](./Readme_dev.md)
