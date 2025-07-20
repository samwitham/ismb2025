# FROM rocker/r2u:latest
FROM ghcr.io/prefix-dev/pixi:latest
LABEL org.opencontainers.image.source=https://github.com/samwitham/ismb2025
LABEL org.opencontainers.image.title=single_cell_perturbation_modelling
LABEL org.opencontainers.image.version=0.1
LABEL org.opencontainers.image.description="This is an image for running single cell perturbation modelling"

# ARG PYTHON_VERSION=3.10
# make project dir
RUN mkdir /project

ENV CONDA_OVERRIDE_CUDA=12.0

# create pyproject.toml file with CUDA support
RUN cat <<EOF > /project/pyproject.toml
[project]
name = "single_cell_perturbation_modelling"
version = "0.1.0"
description = "Default template for Pixi package"
authors = [
    {name = "samwitham"},
]
readme = "README.md"
license = {text = "MIT"}

[tool.pixi.project]
channels = ["conda-forge", "bioconda"]
platforms = ["linux-64"]

[tool.pixi.feature.scpram.dependencies]
python = "==3.8"
scanpy = "==1.9.3"
optuna = "*"
ipywidgets = "*"
ipykernel = "*"


[tool.pixi.feature.scgen.dependencies]
python = "==3.11"
scanpy = "*"
scvi-tools = "*"
optuna = "*"
ipywidgets = "*"
ipykernel = "*"
pytorch-gpu = "*"
pertpy = "*"

[tool.pixi.feature.ailcm.dependencies]
python = "==3.10"
ipywidgets = "*"
ipykernel = "*"
accelerate = "*"
captum = "*"
pytorch-gpu = "*"
pytorch_geometric = "*"
dcor = "*"
scikit-misc = "*"
anndata = "*"
h5py = "*"
ipython = "*"
loguru = "*"
matplotlib = "*"
numpy = "*"
packaging = "*"
pandas = "*"
psutil = "*"
pyyaml = "*"
scanpy = "*"
scikit-learn = "*"
scipy = "*"
seaborn = "*"
tqdm = "*"
numexpr = "*"
transformers = "*"

[tool.pixi.feature.ailcm.pypi-dependencies]
torchkeras = "*"
cell-gears = "*"
scperturb = "*"
dataset = "*"
tables = "*"

[tool.pixi.feature.scpram.pypi-dependencies]
scpram = "*"

[tool.pixi.feature.scpram.pypi-options]
extra-index-urls = ["https://download.pytorch.org/whl/cu116"]

[tool.pixi.feature.scgen.pypi-dependencies]
scgen = "*"
# pertpy = "*"

# # Feature Definitions for CUDA
# [tool.pixi.feature.scpram]
# system-requirements = {cuda = "11.6"}

[tool.pixi.feature.scgen.system-requirements]
cuda = "12"

[tool.pixi.feature.ailcm.system-requirements]
cuda = "12"

[tool.pixi.environments]
scpram = ["scpram"]
scgen = ["scgen"]
ailcm = ["ailcm"]

[tool.pixi.tasks]
install-kernel = "python -m ipykernel install --user --name pixi-env --display-name 'Pixi Env'"
install-all = { depends-on =[
    "install-kernel"
], cmd = "echo 'All packages installed successfully'"}
EOF

# # Create entrypoint script to detect GPU and use correct environment
# RUN cat <<EOF > /project/entrypoint.sh
# #!/bin/bash
# # Check if NVIDIA GPU is available
# if command -v nvidia-smi &> /dev/null; then
#     # Use CUDA environment if GPU is available
#     pixi shell -e cuda
# else
#     # Use default environment otherwise
#     pixi shell
# fi
# exec "\$@"
# EOF

# RUN chmod 700 /project/entrypoint.sh

WORKDIR /project

# add default channels pixi config set default-channels '["conda-forge", "bioconda"]'
# RUN pixi config set default-channels '["conda-forge", "bioconda"]'

# Enable post-link scripts for packages that need them (like Bioconductor packages)
# RUN pixi config set --local run-post-link-scripts insecure

# install git
RUN apt-get update && apt-get install -y git procps locales apt-utils libgsl-dev libicu-dev libcurl4-openssl-dev \
    libnode-dev \
    libxml2-dev \
    make \
    pandoc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Generate locale to fix locale warnings
RUN locale-gen en_US.UTF-8 

# install cuda
# RUN pixi install --manifest-path pyproject.toml --environment cuda
#&& \
# update-locale LANG=en_US.UTF-8
# # Set locale environment variables
# ENV LANG=en_US.UTF-8
# ENV LC_ALL=en_US.UTF-8
# ENV LANGUAGE=en_US.UTF-8

#numpy matplotlib seaborn pandas polars biopython

# # Create a cache directory for Pixi
# RUN mkdir -p /tmp/pixi-cache

# # Use BuildKit cache for Pixi installs
# RUN --mount=type=cache,target=/tmp/pixi-cache \
#     PIXI_CACHE_DIR=/tmp/pixi-cache pixi install --manifest-path pyproject.toml --environment scpram --verbose
# RUN --mount=type=cache,target=/tmp/pixi-cache \
#     PIXI_CACHE_DIR=/tmp/pixi-cache pixi install --manifest-path pyproject.toml --environment scgen --verbose

# Install PyPI dependencies from pyproject.toml
RUN pixi install --manifest-path pyproject.toml --environment scgen --verbose
RUN pixi install --manifest-path pyproject.toml --environment scpram --verbose
RUN pixi install --manifest-path pyproject.toml --environment ailcm --verbose


# Run specific tasks that you want in the container
RUN pixi run -e scpram install-all
RUN pixi run -e scgen install-all
RUN pixi run -e ailcm install-all

# Manually clone scMulan (no pip install needed)
RUN git clone https://github.com/SuperBianC/scMulan.git /project/scMulan

# Optionally: add scMulan to PYTHONPATH for import
ENV PYTHONPATH="/project/scMulan:$PYTHONPATH"

# Place executables in the environment at the front of the path
# ENV PATH="/project/.pixi/envs/cuda/bin:/project/.pixi/envs/default/bin:$PATH"
ENV PATH="/project/.pixi/envs/scpram/bin:/project/.pixi/envs/scgen/bin:$PATH"

# ARG GITHUB_PAT
# # set R env
# ENV GITHUB_PAT=$GITHUB_PAT