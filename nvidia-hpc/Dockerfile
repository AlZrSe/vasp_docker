# Set build environment variables
ARG VASP_VERSION=6.3.2
# Set to true to run VASP test suite
ARG BUILD_TEST=false

# Build stage
FROM nvcr.io/nvidia/nvhpc:25.1-devel-cuda_multi-ubuntu22.04 AS build

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ARG VASP_VERSION
ARG BUILD_TEST

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    rsync \
    libfftw3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PATH=/usr/local/bin:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/extras/qd/lib/:/usr/lib/x86_64-linux-gnu/:/opt/nvidia/hpc_sdk/Linux_x86_64/2025/math_libs/lib64:$LD_LIBRARY_PATH
ENV FFTW_ROOT=/vasp
ENV FFTW=/vasp
ENV QD=/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/extras/qd/
ENV NCCL=/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/comm_libs/nccl/lib/

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
RUN if [ "${VASP_VERSION%.*}" = "6.1" ]; then \
    cp /vasp/vasp.${VASP_VERSION}/arch/makefile.include.linux_pgi_acc /vasp/vasp.${VASP_VERSION}/makefile.include \
    && sed -i 's/-ta=tesla:cc30,cc35,cc50,cc60,cc70,cuda10.1/-gpu=cuda12.6/' /vasp/vasp.${VASP_VERSION}/makefile.include \
    && sed -i 's/-Mcuda/-cuda/g' /vasp/vasp.${VASP_VERSION}/makefile.include \
    && sed -i 's/-ta=tesla:nollvm//' /vasp/vasp.${VASP_VERSION}/makefile.include; \
    else \
    cp /vasp/vasp.${VASP_VERSION}/arch/makefile.include.nvhpc_acc /vasp/vasp.${VASP_VERSION}/makefile.include \
    && sed -i 's/-gpu=cc60,cc70,cc80,cuda11.0//' /vasp/vasp.${VASP_VERSION}/makefile.include; \
    fi

RUN make std ncl gam

# Testing VASP
RUN if [ "$BUILD_TEST" = "true" ] ; then \
        make test; \
    fi

# Runtime stage
FROM nvcr.io/nvidia/nvhpc:25.1-runtime-cuda12.6-ubuntu22.04

# Set environment variables
ARG VASP_VERSION
ENV LD_LIBRARY_PATH=/usr/local/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/25.1/compilers/extras/qd/lib/:/usr/lib/x86_64-linux-gnu/:/opt/nvidia/hpc_sdk/Linux_x86_64/2025/math_libs/lib64:$LD_LIBRARY_PATH

COPY --from=build /vasp/vasp.${VASP_VERSION}/bin/* /usr/local/bin/

# Switch back to root for system operations
USER root

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    libfftw3-double3 \
    sudo \
        && rm -rf /var/lib/apt/lists/*

# Copy VASP executable to /usr/local/bin, setup task directory and remove source code
RUN chmod 755 /usr/local/bin/vasp_* \
    && groupadd -r vasp && groupadd -r mpi && useradd -r -g vasp -m vasp \
    && usermod -a -G mpi vasp \
    && mkdir /task \
    && chown -R vasp:vasp /task \
    && echo "vasp ALL=(ALL) NOPASSWD: /usr/bin/chown, /usr/bin/chmod" >> /etc/sudoers.d/vasp

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER vasp
WORKDIR /task

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]