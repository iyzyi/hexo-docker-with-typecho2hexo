#! /bin/bash

if [ ! -e "${ROOTDIR}/first_flag" ]; then

    # 自定义域名
    echo "${DOMAIN}" > ${ROOTDIR}/source/CNAME

    # 生成about和categories页面，删除hello word文章
    cd ${ROOTDIR}
    hexo new page categories
    hexo new page about
    sed '1atype: categories' -i ${ROOTDIR}/source/categories/index.md
    sed '1atype: about' -i ${ROOTDIR}/source/about/index.md
    echo -e "为最大可能地减少不可抗力为博客访问带来的影响，兹决定采用typecho为主、hexo为辅的冗余备份模式。\n本站仅作应急查询档案，欢迎优先访问主站：<http://iyzyi.com>\n" >> ${ROOTDIR}/source/about/index.md
    rm -rf ${ROOTDIR}/source/_posts/*

    # git配置，ssh密钥
    git config --global user.name "${GITHUBUSER}" && \
    git config --global user.email "${GITHUBEMAIL}" && \
    ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa 2>/dev/null <<< y >/dev/null
    #from: https://stackoverflow.com/questions/43235179/how-to-execute-ssh-keygen-without-prompt
    echo -e "\033[33m下侧是连接github的ssh公钥，请复制并粘贴到github的settings -> SSH and GPC keys -> New SSH key中。\033[0m"
    echo "请确保给予write权限！（定时任务如果没有成功发布，先检查此项）"
    a=`cat /root/.ssh/id_rsa.pub`
    echo -e "\033[34m$a\033[0m"

    # ssh将自动将新的主机密钥添加到用户已知的主机文件中，以免脚本运行时需要输入yes
    # from https://superuser.com/questions/1368606/shell-how-to-inhibit-ssh-yes-or-no-input-for-are-you-sure-you-want-to-continue-c
    sed 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' -i /etc/ssh/ssh_config
    
    # 第一次执行typecho2hexo.py
    read -p "在Github设置好密钥后请按回车"
    python3 ${ROOTDIR}/typecho2hexo.py

    # 向/etc/environment添加环境变量，因为crontab不读取系统环境变量，但会从/etc/environment读取
    # from https://stackoverflow.com/a/34492957
    rm -rf /etc/environment
    env >> /etc/environment
    service cron restart
    # 创建定时任务，每3小时执行一次
    # https://segmentfault.com/q/1010000007383349
    (crontab -l ; echo "1 */3 * * * python3 ${ROOTDIR}/typecho2hexo.py >> ${ROOTDIR}/crontab.log 2>&1;") | crontab -
    # 显示当前的定时任务
    echo "当前的定时任务有："
    crontab -l

    # 创建初始化标记
    touch "${ROOTDIR}/first_flag"

    # 使得容器执行完start.sh后不会退出
    # https://stackoverflow.com/questions/42218957/dockerfile-cmd-instruction-will-exit-the-container-just-after-running-it
    echo "即将进入容器内部，退出请按Ctrl+P+Q"
    /bin/bash
else
    echo "${ROOTDIR}/first_flag已存在，start.sh不执行。"
fi