# Gemini3D External Library build/install scripts

Scripts to build/install external libraries used by Gemini3D.

The most common task is to install a recent version of CMake:

```sh
cmake -P install_cmake.cmake
```

If that script doesn't work, try to build CMake:

```sh
cmake -P build_cmake.cmake
```


Other builds scripts are for:

* MPI:  OpenMPI, MPICH
* Zstd
* Ninja
