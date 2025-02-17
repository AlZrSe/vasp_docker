## Dockerfile for VASP

This repository contains a Dockerfile for building a Docker image for VASP (Vienna Ab initio Simulation Package).

**Important:** Building this image requires a VASP source code archive, which is only available to licensed users. You must obtain the source code from the official VASP developers before proceeding.

### Aim of the project
This project aims to simplify the deployment of VASP through containerization. Beyond just VASP compilation, it provides a foundation for creating complex multi-container environments using docker-compose, incorporating various post-processing tools like pymatgen, DFTTK, and other materials science utilities. This approach ensures consistent, reproducible environments across different systems while managing dependencies efficiently. Also this project provides a fast installation of core VASP software on Linux/MacOS/Windows OS.

### Prerequisites

*   Docker installed on your system.
*   A licensed copy of the VASP source code (e.g., `vasp.6.3.2.tgz`). Place this archive in the same directory as the Dockerfile.
*   Change corresponding environment variables (VASP_VERSION and BUILD_TEST) in Dockerfile.

### Building the Image

1.  Clone this repository (or copy the Dockerfile):

    ```bash
    git clone https://github.com/AlZrSe/vasp-docker.git
    cd vasp-docker
    ```

2.  Select a corresponding directory with desired toolchain (compiler + parallelization + scientific libraries) and place your VASP source code archive (e.g., `vasp.6.3.2.tgz`) in the this directory along with the Dockerfile.

3.  Build the Docker image:

    ```bash
    docker build -t vasp:latest .
    ```

    This command builds the image and tags it as `vasp:latest`. You can change the tag if you prefer.

### Running the Container

To run a container from the built image:

```bash
docker run -it vasp:latest
```

If you want to run on all available cores you may run:

#### For Windows PowerShell
```ps
$cores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

docker run -it --rm `
    -v ${PWD}:/task `
    --privileged `
    --hostname mpi-container `
    --network host `
    --user vasp `
    vasp:latest `
    mpiexec -np $cores vasp_std
```

#### For Linux/macOS bash
```bash
cores=$(nproc)

docker run -it --rm \
    -v ${PWD}:/task \
    --privileged \
    --hostname mpi-container \
    --network host \
    --user vasp \
    vasp:latest \
    mpiexec -np $cores vasp_std
```

`vasp_ncl` and `vasp_gam` commands also available.

For GPU support add additional parameters `--gpus all --env NVIDIA_DISABLE_REQUIRE=1`.

## Tested toolchains and versions:

* gcc + openmpi + libfftw3 + openblas + scalapack from standard Ubuntu 24.04 with VASP 6.3.2 (also with VASP's `make test`)