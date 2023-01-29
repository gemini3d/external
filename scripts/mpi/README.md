# Build MPI

This mini-project is to build MPICH or OpenMPI (Default) for those systems not having MPI for the desired compiler.

```sh
cmake -Bbuild -Dmpich=no --install-prefix $HOME/my_mpi

cmake --build build
```

setting `-Dmpich=yes` builds MPICH instead of the default OpenMPI.
