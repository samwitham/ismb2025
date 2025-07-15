# This is the image we are going add micromamba to:
# only seems to work when you specify :main tag rather than :latest
# FROM ghcr.io/samwitham/ismb2025/cell_comm:sha-4717e1d
# use registry.gitlab.com/sysbiobig/ismb-eccb-2025-tutorial-vt3
FROM registry.gitlab.com/sysbiobig/ismb-eccb-2025-tutorial-vt3:latest

# FROM seurat_plotting:latest

# python version
ARG PYTHON_VERSION=3.10

# The installer requires curl (and certificates) to download the release archive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    libudunits2-dev \
    libgdal-dev \
    gdal-bin \
    libproj-dev \
    proj-data \
    proj-bin \
    libgeos-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install pixi curl -fsSL https://pixi.sh/install.sh | bash
# RUN curl -fsSL https://pixi.sh/install.sh | bash
ARG PIXI_VERSION=0.49.0
RUN curl -Ls \
    "https://github.com/prefix-dev/pixi/releases/download/v${PIXI_VERSION}/pixi-$(uname -m)-unknown-linux-musl" \
    -o /usr/local/bin/pixi && chmod +x /usr/local/bin/pixi

# add pixi to path
ENV PATH="/usr/local/bin:$PATH"



# make workdir
RUN mkdir -p /project

# go into proiject dir
WORKDIR /project

# create pyproject.toml file with CUDA support
RUN cat <<EOF > /project/pyproject.toml
[project]
name = "macomics"
version = "0.1.0"
description = "Default template for Pixi package"
authors = [
    {name = "samwitham", email = "witham@macomics.com"},
]

requires-python = "==$PYTHON_VERSION.*"
readme = "README.md"
license = {text = "MIT"}

[tool.pixi.project]
channels = ["conda-forge", "bioconda"]
platforms = ["linux-64"]

[tool.pixi.pypi-dependencies]
macomics = { path = ".", editable = true }
nichesphere = { git = "https://github.com/CostaLab/Nichesphere", subdirectory = "nichesphere" }
community-layout = "~=1.0.6"
liana = "~=1.5.1"
cellphonedb = "*"
pycrosstalker = "*"
ipykernel = "*"

# # Feature Definitions for CUDA
# [tool.pixi.feature.cuda]
# system-requirements = {cuda = "12"}

# # Environment with CUDA
# [tool.pixi.environments]
# cuda = ["cuda"]

[tool.pixi.tasks]
install-kernel = "python -m ipykernel install --user --name pixi-env --display-name 'Pixi Env'"
install-rkernel = "R -e 'IRkernel::installspec()'"

# install-all task to install all tasks
install-all = { depends-on =[
    "install-kernel",
    "install-rkernel"
], cmd = "echo 'All packages installed successfully'"}
EOF

# pixi add to path
ENV PATH="/project/.pixi/envs/default/bin:$PATH"


# add default channels pixi config set default-channels '["conda-forge", "bioconda"]'
# RUN pixi config set default-channels '["conda-forge", "bioconda"]'

# go into proiject dir

RUN pixi config set --local run-post-link-scripts insecure

# # Ensure the installed binary is on the `PATH`
# ENV PATH="/root/.local/bin/:$PATH"
RUN pixi add ipykernel ruff pre-commit radian pygraphviz dvc

# Install all packages defined in the project
# RUN ulimit -n 4096 && pixi install
RUN pixi install --manifest-path pyproject.toml --verbose

# RUN uv pip install jupyter-client --system
RUN pixi global install jupyter_client

# R add install.packages("precommit")
# install R packages
RUN R -e "install.packages(c('precommit'))"

# install tasks
RUN pixi run install-all

# Generate locale to fix locale warnings
RUN locale-gen en_US.UTF-8 

# # install IRkernel and languageserver and precommit
# RUN R -e "install.packages('git2r', dependencies = TRUE)"
# RUN install.r languageserver precommit rzmq repr IRkernel IRdisplay
# RUN R -e "IRkernel::installspec()"

# install Oh My Zsh
# Default powerline10k theme, no plugins installed
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    # install conda zsh autocompletion
    -p https://github.com/esc/conda-zsh-completion

# Ensure .zshrc exists before modifying it
RUN touch ${HOME}/.zshrc && \
    sed -i 's/source \$ZSH\/oh-my-zsh.sh/source \$ZSH\/oh-my-zsh.sh\nautoload -U compinit \&\& compinit\n\
    eval "\$(pixi completion --shell zsh)"/g' ${HOME}/.zshrc

# set up git config
RUN git config --global user.name "witham" && \
    git config --global user.email "45053242+samwitham@users.noreply.github.com"


ENTRYPOINT ["bash", "-c", "ulimit -n 65536 && exec \"$@\"", "--"]