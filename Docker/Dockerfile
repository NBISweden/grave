# G-ALN: GPU implementation of bwa aln / bwa index (https://github.com/bilalbioinfo/galn)
# Run with the NVIDIA container toolkit, e.g. `docker run --gpus all ...`
# or with Apptainer/Singularity: `apptainer exec --nv ...`

ARG CUDA_VERSION=12.4.1
ARG UBUNTU_VERSION=22.04

########## Build stage ##########
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS build

ARG GALN_VERSION=v0.2.7
# Default is Volta to Hopper (70 75 80 86 89 90); pin to e.g. "90" for a faster, smaller build
ARG CUDA_ARCHS="70;75;80;86;89;90"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        git \
    && rm -rf /var/lib/apt/lists/*

# Third-party dependencies (zlib-ng, libsais, libcubwt) are vendored in the repo, no submodules needed
RUN git clone --depth 1 --branch ${GALN_VERSION} https://github.com/bilalbioinfo/galn.git /opt/galn

WORKDIR /opt/galn
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
    && cmake --build build -j "$(nproc)" \
    && strip build/galn

########## Runtime stage ##########
FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

LABEL org.opencontainers.image.source="https://github.com/bilalbioinfo/galn" \
      org.opencontainers.image.description="G-ALN: GPU implementation of bwa aln and bwa index" \
      org.opencontainers.image.licenses="GPL-3.0"

# libgomp is needed for OpenMP; zlib is statically linked (zlib-ng); samtools is used by the pipeline for filtering/sorting
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 \
        samtools \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/galn/build/galn /usr/local/bin/galn

WORKDIR /data
CMD ["galn"]
