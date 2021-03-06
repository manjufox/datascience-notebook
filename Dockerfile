FROM jupyter/datascience-notebook:latest

USER root

# この部分 Copyright (c) 2019,2020 NVIDIA CORPORATION. All rights reserved.
### install cuda - copied from nvidia cuda dockerfiles cuda 10.2
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/10.2/ubuntu18.04-x86_64/base/Dockerfile

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 10.2.89
ENV CUDA_PKG_VERSION 10-2=$CUDA_VERSION-1
# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-$CUDA_PKG_VERSION \
    cuda-compat-10-2 \
    && ln -s cuda-10.2 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.2 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441"

##### ユーザを戻しておく
USER jovyan

##### nv-cuda インストール完了

# この下に、個人用の設定を追加...
# ... dockerfile 続き
RUN julia -e 'using Pkg; Pkg.add("Flux");' && \
    julia -e 'using Pkg; Pkg.add("CUDA");' && \
    julia -e 'using Pkg; Pkg.add("Conda");' && \
    julia -e 'using Pkg; Pkg.add("IJulia");' && \
    julia -e 'using Pkg; Pkg.add("Gadfly");' && \
    julia -e 'using Pkg; Pkg.add("Gen");' && \
    julia -e 'using Pkg; Pkg.add("Plots");' && \
    julia -e 'using Pkg; Pkg.add("Pluto");' && \
    julia -e 'using Pkg; Pkg.add("DifferentialEquations");' && \
    julia -e 'using Pkg; Pkg.add("Images");'
#RUN julia -e 'using Pkg; Pkg.API.precompile()'

# conda/pythonの部
# コレ書かないと失敗することがある
# FROM tensorflow/tensorflow:2.0.4-py3-jupyter
RUN conda config --set channel_priority false && \
    conda update --all  && \
# パッケージ入れる
 conda install -c anaconda tensorflow-gpu && \
 conda install -c anaconda tensorflow-hub && \
 conda install -c anaconda tensorflow-datasets && \
 conda install -y pydot graphviz 

USER root

 # nodejsの導入
RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - \
    && sudo apt-get install -y nodejs

RUN jupyter labextension install @jupyterlab/debugger

RUN jupyter labextension install @lckr/jupyterlab_variableinspector
RUN jupyter labextension install @jupyterlab/toc
RUN pip install autopep8 jupyterlab_code_formatter

RUN jupyter labextension install @ryantam626/jupyterlab_code_formatter
RUN jupyter serverextension enable --py jupyterlab_code_formatter

RUN pip install ipywidgets
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension

# 変数や行列の中身を確認
RUN jupyter labextension install @lckr/jupyterlab_variableinspector

# 自動整形
RUN pip install autopep8 \
    && pip install jupyterlab_code_formatter \
    && jupyter labextension install @ryantam626/jupyterlab_code_formatter \
    && jupyter serverextension enable --py jupyterlab_code_formatter

RUN cd && \
    wget https://linux.kite.com/dls/linux/current && \
    chmod 777 current && \
    sed -i 's/"--no-launch"//g' current > /dev/null && \
    ./current --install ./kite-installer

RUN pip install "jupyterlab-kite>=2.0.2"

USER jovyan

COPY ./requirements.txt ./
RUN pip install -r requirements.txt

USER root

RUN apt-get install -y \
  sudo \
  wget \
  vim \
  mecab \
  libmecab-dev \
  mecab-ipadic-utf8 \
  git \
  make \
  curl \
  xz-utils \
  file

# WORKDIR /opt

# RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh && \
#   sh Anaconda3-2020.07-Linux-x86_64.sh -b -p /opt/anaconda3 && \
#   rm -f Anaconda3-2020.07-Linux-x86_64.sh
# ENV PATH /opt/anaconda3/bin:$PATH

RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git ; exit 0
RUN cd mecab-ipadic-neologd && \
  ./bin/install-mecab-ipadic-neologd -n -y && \
  echo "dicdir=/usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd">/etc/mecabrc


USER jovyan
# RUN conda update -n base -c defaults conda

RUN pip install mecab-python3 \
  Janome \
  jaconv \
  tinysegmenter==0.3 \
  gensim \
  unidic-lite \
  japanize-matplotlib

# RUN conda install -c conda-forge \
#   newspaper3k && \
#   conda install beautifulsoup4 \
#   lxml \
#   html5lib \
#   requests

# WORKDIR /work


COPY ./jupyter_lab_config.py /home/jovyan/.jupyter/
CMD ["jupyter", "lab"]