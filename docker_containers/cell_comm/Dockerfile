# FROM rocker/r2u:latest
FROM ghcr.io/prefix-dev/pixi:latest
LABEL org.opencontainers.image.source=https://github.com/samwitham/ismb2025
LABEL org.opencontainers.image.title=cell_comm
LABEL org.opencontainers.image.version=0.1
LABEL org.opencontainers.image.description="This is an image for running cell-cell comunication analysis"

ARG PYTHON_VERSION=3.10
# make project dir
RUN mkdir /project

# create pyproject.toml file with CUDA support
RUN cat <<EOF > /project/pyproject.toml
[project]
name = "cell_communication"
version = "0.1.0"
description = "Default template for Pixi package"
authors = [
    {name = "samwitham"},
]

requires-python = "==$PYTHON_VERSION.*"
readme = "README.md"
license = {text = "MIT"}

[tool.pixi.project]
channels = ["https://prefix.dev/conda-forge","bioconda", "dnachun"]
platforms = ["linux-64"]

[tool.pixi.pypi-dependencies]
cell_communication = { path = ".", editable = true }
cellphonedb = "~=5.0"
nichesphere = { git = "https://github.com/CostaLab/Nichesphere", subdirectory = "nichesphere" }
community-layout = "~=1.0.6"
liana = "~=1.5.1"

# # Feature Definitions for CUDA
# [tool.pixi.feature.cuda]
# system-requirements = {cuda = "12"}

# # Environment with CUDA
# [tool.pixi.environments]
# cuda = ["cuda"]

[tool.pixi.tasks]
install-kernel = "python -m ipykernel install --user --name pixi-env --display-name 'Pixi Env'"
install-rkernel = "R -e 'IRkernel::installspec()'"
# install-scseqcomm = "R -e 'pak::pkg_install(\"gitlab::sysbiobig/scseqcomm\")'"
install-scseqcomm = "R -e 'remotes::install_gitlab(\"sysbiobig/scseqcomm\")'"
install-add2ggplot = "R -e 'pak::pkg_install(\"github::JiaxiangBU/add2ggplot\")'"
install-crosstalker = "R -e 'pak::pkg_install(\"github::CostaLab/CrossTalkeR\")'"
install-twosamplemr = "R -e 'pak::pkg_install(\"github::MRCIEU/TwoSampleMR\")'"
install-mrinstruments = "R -e 'pak::pkg_install(\"github::MRCIEU/MRInstruments\")'"
install-gwasglue = "R -e 'pak::pkg_install(\"github::mrcieu/gwasglue\")'"

# install_all task to install all tasks
install-all = { depends-on =[
    "install-kernel",
    "install-rkernel",
    "install-scseqcomm",
    "install-add2ggplot",
    "install-crosstalker",
    "install-twosamplemr",
    "install-mrinstruments",
    "install-gwasglue"
], cmd = "echo 'All R packages installed successfully'"}
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
RUN pixi config set --local run-post-link-scripts insecure

# install git
RUN apt-get update && apt-get install -y git

RUN apt-get install -y procps apt-utils libgsl-dev locales libicu-dev libcurl4-openssl-dev \
    libnode-dev \
    libxml2-dev \
    make \
    pandoc \
    libudunits2-dev \
    libgdal-dev \
    gdal-bin \
    libproj-dev \
    proj-data \
    proj-bin \
    libmagick++-dev \
    libgeos-dev && \
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

# add R dependencies using pixi add
RUN pixi add r-devtools r-biocmanager r-remotes r-base r-roxygen2 r-testthat r-usethis r-argparser r-ggplot2 r-data.table r-svglite r-rcpp r-future bioconductor-edger r-dplyr r-matrix r-purrr r-box r-seurat r-bit64 r-openxlsx r-ape r-pheatmap r-ggpubr r-qs r-markdown r-ggnewscale r-emmeans r-multcomp r-readxl r-progress r-ggalt r-ggprism r-hdf5r r-pak bioconductor-geoquery bioconductor-biomart r-essentials mmseqs2 ipykernel r-git2r r-languageserver r-precommit r-rzmq r-irkernel r-irdisplay dvc "pygraphviz==1.14" mudata umap-learn "scanpy==1.10.4" bioconductor-gosemsim r-ggfun r-ggplotify bioconductor-org.hs.eg.db bioconductor-org.Mm.eg.db r-scico r-psych r-chorddiag r-domc r-gtools r-tictoc bioconductor-mast r-bigmemory r-bh r-effsize r-doparallel r-dorng bioconductor-clusterprofiler r-rcurl bioconductor-omnipathr r-knitr r-ggalluvial r-dt r-scales r-htmltools r-factoextra r-colorblindness bioconductor-complexheatmap r-extrafont r-ggridges r-ggnewscale r-gtools r-ggsci r-rstatix r-qpdf bioconductor-enhancedvolcano r-patchwork r-magick r-zeallot r-rcolorbrewer r-magrittr bioconductor-fgsea r-cellchat r-ieugwasr bioconductor-variantannotation
#numpy matplotlib seaborn pandas polars biopython
ARG GITHUB_PAT
# set env
ENV GITHUB_PAT=$GITHUB_PAT

# Install PyPI dependencies from pyproject.toml
RUN pixi install

# Run specific tasks that you want in the container
RUN pixi run install-all

# Place executables in the environment at the front of the path
# ENV PATH="/project/.pixi/envs/cuda/bin:/project/.pixi/envs/default/bin:$PATH"
ENV PATH="/project/.pixi/envs/default/bin:$PATH"

