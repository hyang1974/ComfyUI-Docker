################################################################################
# Dockerfile that builds 'yanwk/comfyui-boot:latest'
# A runtime environment for https://github.com/comfyanonymous/ComfyUI
################################################################################

FROM ubuntu:22.04

LABEL maintainer="hy@yanghong.dev"

# 使用构建参数设置环境变量
ARG http_proxy
ARG https_proxy

# 设置环境变量
ENV http_proxy=$http_proxy
ENV https_proxy=$https_proxy

ENV DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt \
    set -eu \
    && apt update \
    && apt upgrade -y \
    && apt install -y software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt update \
    && apt install -y \
        sudo \
        python3.11 python3-pip \
        g++ cmake \
        git aria2 \
        libgl1-mesa-dev libglib2.0-0 \
    && rm -rf /usr/lib64/python3.11/EXTERNALLY-MANAGED


RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip

# Install PyTorch
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
        torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu121 \
        --extra-index-url https://pypi.org/simple

# For anyone who want to use xFormers, uncomment code block below, and comment "PyTorch" part above.
# This code block will be removed in future.
## Install xFormers (stable version, will specify PyTorch version),
## and Torchvision + Torchaudio (will downgrade to match xFormers' PyTorch version).
## Then upgrade xFormers to dev version, while keeping most dependencies at stable version.
# RUN --mount=type=cache,target=/root/.cache/pip \
#     pip install --break-system-packages \
#         xformers torchvision torchaudio \
#         --index-url https://download.pytorch.org/whl/cu121 \
#         --extra-index-url https://pypi.org/simple \
#     && pip install --break-system-packages \
#         --pre --upgrade xformers \
#         --index-url https://download.pytorch.org/whl/cu121 \
#         --extra-index-url https://pypi.org/simple

# Install ONNX Runtime(ORT) for CUDA 12.x
# ORT is used by DWPose by controlnet_aux. But current ORT release on PyPI only supports CUDA 11.8.
# This fix should be removed once ORT done upgrade.
# Ref: https://onnxruntime.ai/docs/install/
# Ref: https://github.com/Fannovel16/comfyui_controlnet_aux/issues/75
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
        onnxruntime-gpu \
        --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# Dependencies for: ComfyUI,
# InstantID, ControlNet Auxiliary Preprocessors,
# ComfyUI-Manager, Inspire-Pack, Impact-Pack, "Essentials", Efficiency Nodes, Crystools,
# smZNodes(compel, lark)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
        -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt \
        -r https://raw.githubusercontent.com/ZHO-ZHO-ZHO/ComfyUI-InstantID/main/requirements.txt \
        -r https://raw.githubusercontent.com/Fannovel16/comfyui_controlnet_aux/main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Inspire-Pack/main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Pack/Main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Subpack/main/requirements.txt \
        -r https://raw.githubusercontent.com/cubiq/ComfyUI_essentials/main/requirements.txt \
        -r https://raw.githubusercontent.com/jags111/efficiency-nodes-comfyui/main/requirements.txt \
        -r https://raw.githubusercontent.com/crystian/ComfyUI-Crystools/main/requirements.txt \
        compel lark

# Fix for libs (.so files)
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}\
:/usr/lib64/python3.11/site-packages/torch/lib\
:/usr/lib/python3.11/site-packages/nvidia/cuda_cupti/lib\
:/usr/lib/python3.11/site-packages/nvidia/cuda_runtime/lib\
:/usr/lib/python3.11/site-packages/nvidia/cudnn/lib\
:/usr/lib/python3.11/site-packages/nvidia/cufft/lib"

# More libs (not necessary, just in case)
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}\
:/usr/lib/python3.11/site-packages/nvidia/cublas/lib\
:/usr/lib/python3.11/site-packages/nvidia/cuda_nvrtc/lib\
:/usr/lib/python3.11/site-packages/nvidia/curand/lib\
:/usr/lib/python3.11/site-packages/nvidia/cusolver/lib\
:/usr/lib/python3.11/site-packages/nvidia/cusparse/lib\
:/usr/lib/python3.11/site-packages/nvidia/nccl/lib\
:/usr/lib/python3.11/site-packages/nvidia/nvjitlink/lib\
:/usr/lib/python3.11/site-packages/nvidia/nvtx/lib"

# Create a low-privilege user
RUN printf 'CREATE_MAIL_SPOOL=no' >> /etc/default/useradd \
    && mkdir -p /home/runner /home/scripts \
    && groupadd runner \
    && useradd runner -g runner -d /home/runner \
    && chown runner:runner /home/runner /home/scripts

COPY --chown=runner:runner scripts/. /home/scripts/

USER runner:runner
VOLUME /home/runner
WORKDIR /home/runner
EXPOSE 8188
ENV CLI_ARGS=""
CMD ["bash","/home/scripts/entrypoint.sh"]
