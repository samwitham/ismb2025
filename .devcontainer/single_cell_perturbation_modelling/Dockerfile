# This is the image we are going add micromamba to:
# only seems to work when you specify :main tag rather than :latest
FROM ghcr.io/samwitham/ismb2025/single_cell_perturbation_modelling:sha-4c491d8

# FROM seurat_plotting:latest

RUN apt update && apt upgrade -y

RUN apt install -y git

# # Ensure the installed binary is on the `PATH`
# ENV PATH="/root/.local/bin/:$PATH"
# RUN pixi add ipykernel ruff pre-commit

# RUN uv pip install jupyter-client --system
RUN pixi global install jupyter_client ruff pre-commit ipykernel dvc

# Generate locale to fix locale warnings
RUN locale-gen en_US.UTF-8 

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