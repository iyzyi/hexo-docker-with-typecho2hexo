FROM ubuntu
USER root

ENV LANG C.UTF-8
ENV DOMAIN=hexo.iyzyi.com
ENV ROOTDIR=/blog
ENV GITHUBUSER=iyzyi
ENV GITHUBEMAIL=kljxn@qq.com

ENV DB_HOST=172.18.0.4
ENV DB_USER=root
ENV DB_PWD=root
ENV DB_NAME=blog
ENV DB_PRE=typecho

WORKDIR ${ROOTDIR}

# 安装git, crontab等
RUN apt-get update && \
    apt-get install -y git && \
    apt-get install -y vim && \
    apt-get install -y net-tools && \
    apt-get install -y cron

# 安装nodejs 10.x
RUN apt-get install -y curl && \
    apt-get install -y sudo && \
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && \
    apt-get install -y nodejs

# 安装typecho2hexo.py所需的模块
RUN apt-get install -y python3-pip && \
    python3 -m pip install PyMySQL && \
    python3 -m pip install oss2

#安装hexo博客和next主题
RUN npm install -g hexo-cli && \
    hexo init && \
    npm install && \
    npm i hexo-deployer-git && \
    git clone https://github.com/theme-next/hexo-theme-next.git themes/next && \
    npm install hexo-generator-searchdb --save && \
    hexo clean

COPY avatar.jpg ${ROOTDIR}/source/images/avatar.jpg
COPY index_config.yml ${ROOTDIR}/_config.yml
COPY theme_config.yml ${ROOTDIR}/themes/next/_config.yml
COPY typecho2hexo.py ${ROOTDIR}/typecho2hexo.py
COPY start.sh ${ROOTDIR}/start.sh
RUN chmod +x ${ROOTDIR}/start.sh && \
    chmod +x ${ROOTDIR}/typecho2hexo.py

CMD ${ROOTDIR}/start.sh