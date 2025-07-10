# **ISMB ECCB 2025 - Tutorial VT3**

Welcome to the repository for the **ISMB-ECCB 2025 Tutorial VT3** on **computational analysis of cell-cell communication**, held virtually on **July 15, 2025**.
This repository contains the tutorial materials and instructions to follow the hands-on sessions.

## **Setup Instructions (Before the Tutorial)**

To participate in the hands-on sessions, you’ll need to set up your environment and download the required materials **before July 15, 2025**.

You can find detailed setup instructions in the **Instruction_Guide.pdf** included in this repository or available https://drive.google.com/drive/folders/1Wk7FuDHHfg-JUySs3XMpz8sA-oeIsJWt?usp=drive_link.
This guide walks you through downloading the Jupyter notebooks and datasets, and provides step-by-step instructions for running the tutorial environment using Docker.

> ⚠️ **Please make sure to review the guide and complete your setup ahead of the tutorial to avoid delays during the hands-on sessions.**

### _Tutorial Materials_

This repository contains the **Jupyter notebooks** used during the hands-on sessions of the tutorial. Both .ipynb (Jupyter) and .html (rendered) versions are provided to facilitate offline viewing and sharing.

The datasets used in these notebooks will be made available via Zenodo at https://zenodo.org/records/15756745

**Repository Structure**

```
└── notebooks
    ├── HTML
    └── jupyter
        ├── additional
        │   ├── comparative_or_spatial
        │   └── single_condition
        └── main
            ├── First  ## Here are the notebooks used into the first half of the tutorial
            └── Second ## Here are the notebooks used into the second half of the tutorial

```

### _Tutorial Environment_

This repository includes access to a **Docker image** that will be used during the tutorial, available at: https://gitlab.com/sysbiobig/ismb-eccb-2025-tutorial-vt3/container_registry.
The Docker image comes preconfigured with all necessary libraries, tools, and software required to follow the hands-on exercises.

> ⚠️ **Using this Docker container is strongly recommended** to ensure consistency and reproducibility across systems. That said, participants are free to configure their local environments independently. Please note, however, that results may vary slightly depending on local system settings and installed package versions, and we cannot guarantee full support outside the Docker setup.

> ⚠️ **Platform support**: This Docker setup is primarily built and tested on **Intel/AMD (x86_64) architecture**. Docker may work for **ARM-base systems**, but performance issues or compatibility problems may occur. If Docker doesn't work on your system, we recommend setting up your environment manually.

## **Tutorial Description**

Tissues and organs are complex and highly-organized systems composed of diverse cells that work together to maintain homeostasis, drive development and mediate complex disease progression as Myocardial Infarction (Kuppe et al. 2022). A key focus of modern biology is understanding how heterogeneous populations of cells coexist and communicate with each other (intercellular signaling), how they properly respond (intracellular signaling) within a tissue and organ system and how these processes vary across different experimental conditions (comparative analysis). Recently, a rapid expansion of computational tools exploring the expression of ligand and receptor has enabled the systematic inference of cell-cell communication from single-cell transcriptomics and spatial transcriptomics data (Armingol et al. 2021; Armingol, Baghdassarian, and Lewis 2024). These are crucial in unravelling the complex landscape of biological systems.

This tutorial aims to provide a comprehensive introduction to computational approaches for cell-cell communication inference using high throughput transcriptomics data. It covers the fundamental concepts of cellular communication and assumptions underlying analysis focusing on the main computational methods used in the field. This includes computational approaches for inter-cellular communication inference (CellphoneDB (Efremova et al. 2020); LIANA (Dimitrov et al. 2022, 2024)) and for intra-cellular signals communication (scSeqComm (Baruzzo, Cesaro, and Di Camillo 2022); NicheNet (Browaeys, Saelens, and Saeys 2019)). Next, we will describe approaches for comparative analysis of cell-cell networks in distinct biological conditions (CrossTalkeR (Nagai et al. 2021)) and methods for spatially resolved cell-cell communications (Ischia (Regan-KomitoDaniel 2024); DeepCOLOR (Kojima et al. 2024)).

In the first part of the tutorial, participants will be introduced to the theoretical basis of state-of-the-art computational approaches and will learn how to use representative tools for inferring intercellular signaling and intracellular signaling pathways. In the second part, we will focus on the comparative analyses, i.e. changes of cell-cell communication in two conditions, and subsequently highlighting the unique insights spatial transcriptomics data can provide for understanding tissue architecture and cellular communication. Both sections will be followed by a hands-on component based on the analysis of single cell and spatial transcriptomics data from the myocardial infarction atlas (Kuppe et al. 2022). To promote transparency, all the codes, software tools and the datasets used throughout the tutorial will be available and accessible through open-access repositories (e.g. GitHub repositories or Zenodo platforms).

**Learning Objectives**

- Understanding and identifying the key theoretical concepts of cell-cell communication analysis.
- Learn the foundations of main computational approaches for cell-cell communication inference and develop critical thinking skills to choose and apply the most appropriate tools tailored to the specific research questions and analysis contents.
- Gain hands-on experience in applying these computational methods to real-world data and learn how to interpret and evaluate the results in the context of biological systems: Introduction to computational inference of intercellular and intracellular cell-cell communication.
- Overview of cell-cell communication inference, assumptions and challenges, a priori biological knowledge, current approaches for intercellular and intracellular signaling.
