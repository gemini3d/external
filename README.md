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

## Build all Gemini3D external libraries

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
