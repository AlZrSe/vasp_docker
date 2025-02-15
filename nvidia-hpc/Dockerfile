FROM nvcr.io/nvidia/nvhpc:25.1-devel-cuda_multi-ubuntu22.04 AS build

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set build environment variables
ENV VASP_VERSION=6.3.2
# Set to true to run VASP test suite
ENV BUILD_TEST=false

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    rsync \
    libfftw3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV LD_LIBRARY_PATH=/usr/local/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/extras/qd/lib/
ENV PATH=/usr/local/bin:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/bin:$PATH
ENV FFTW_ROOT=/vasp

# Create working directory
WORKDIR /vasp

# These paths reflect where Ubuntu package manager installs the libraries:
# - FFTW: /usr/lib/x86_64-linux-gnu
RUN ln -s /usr/lib/x86_64-linux-gnu /vasp/lib
# Also for include folder
RUN ln -s /usr/include /vasp/include

# Create non-root user first
RUN groupadd -r vasp && groupadd -r mpi && useradd -r -g vasp -m vasp \
    && usermod -a -G mpi vasp

RUN chown vasp:vasp /vasp

# Switch to non-root user for compilation
USER vasp

# Installing VASP
COPY vasp.${VASP_VERSION}.tgz ./vasp.${VASP_VERSION}.tgz
RUN tar xzf vasp.${VASP_VERSION}.tgz && rm vasp.${VASP_VERSION}.tgz
WORKDIR /vasp/vasp.${VASP_VERSION}
RUN cp /vasp/vasp.${VASP_VERSION}/arch/makefile.include.nvhpc_acc /vasp/vasp.${VASP_VERSION}/makefile.include
RUN sed -i 's/-gpu=cc60,cc70,cc80,cuda11.0//' /vasp/vasp.${VASP_VERSION}/makefile.include


RUN make all

# Testing VASP
RUN if [ "$BUILD_TEST" = "true" ] ; then \
        make test; \
    fi

# Switch back to root for system operations
USER root

# Copy VASP executable to /usr/local/bin, setup task directory and remove source code
RUN cp /vasp/vasp.${VASP_VERSION}/bin/vasp_* /usr/local/bin/ \
    && chmod 755 /usr/local/bin/vasp_* \
    && mkdir /task \
    && chown -R vasp:vasp /task \
    && rm -rf /vasp

# Switch to non-root user
USER vasp
WORKDIR /task