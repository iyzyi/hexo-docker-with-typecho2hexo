# 暂未支持图片自动转换成阿里云oss链接, oss2模块可以不用安装

import pymysql, os, re, html, time, subprocess


class GO():

    def __init__(self):
        self.get_env()
        self.delete()
        if self.mysql():
            self.shell()


    # 时间戳转时间
    def timestamp_to_date(self, time_stamp, format_string="%Y-%m-%d %H:%M:%S"):
        time_array = time.localtime(time_stamp)
        str_date = time.strftime(format_string, time_array)
        return str_date


    #获取ENV变量
    def get_env(self):
        self.rootdir = os.getenv('ROOTDIR')
        self.db_host = os.getenv('DB_HOST')
        self.db_user = os.getenv('DB_USER')
        self.db_pwd = os.getenv('DB_PWD')
        self.db_name = os.getenv('DB_NAME')
        self.db_pre = os.getenv('DB_PRE')

        self.post_dir = '%s/source/_posts' % self.rootdir
        if not os.path.exists(self.post_dir):
            os.makedirs(self.post_dir)


    # 从数据库中获取数据并保存markdown
    def mysql(self):
        try:
            self.db = pymysql.connect(self.db_host, self.db_user, self.db_pwd, self.db_name)
        except Exception as e:
            print('数据库连接失败')
            return False
        else:
            self.cursor = self.db.cursor()

            # 获取目录、目录编号、父级目录编号，最终获得完整的目录从属路径
            self.cursor.execute('SELECT mid,name,parent FROM %s_metas;' % self.db_pre)
            data = self.cursor.fetchall()
            metas_name = {}
            metas_parent = {}
            for i in data:
                mid, name, parent = i[0], i[1], i[2]
                metas_name[mid] = name
                metas_parent[mid] = parent
            metas_path = {}
            for i in metas_name.keys():
                metas_path[i] = metas_name[i]
                mid = i
                while (metas_parent[mid] != 0):
                    mid = metas_parent[mid]
                    metas_path[i] = "%s\n- %s" % (metas_name[mid], metas_path[i])
                #print(metas_path[i])

            # 获取文章和目录的对应关系（cid和mid）
            self.cursor.execute('SELECT cid,mid FROM %s_relationships;' % self.db_pre)
            data = self.cursor.fetchall()
            posts = {}
            for i in data:
                cid, mid = i[0], i[1]
                posts[cid] = mid

            # 获取文章内容，并处理
            self.cursor.execute('SELECT cid,title,text,created FROM %s_contents WHERE type="post" order by created;' % self.db_pre)
            data = self.cursor.fetchall()
            for i in data:
                cid, title, text, created = i[0], i[1], i[2], i[3]

                title = html.unescape(title)
                date = self.timestamp_to_date(int(created))
                categories = metas_path[posts[cid]]
                pre_text = '''---
title: %s
date: %s
categories: \n- %s
---

''' % (title, date, categories)
                
                text = re.sub(r'<!--markdown-->', '', text)
                text = re.sub(r'<!-- *?more *?-->', '', text)
                text = re.sub(r'\r\n', r'\n', text)
                text = pre_text + text

                with open('%s/%s.md' % (self.post_dir, title), 'w', encoding='utf-8')as f:
                    f.write(text)
                print('[download]: %s' % title)
            return True


    # 生成静态页面，上传到github
    # https://stackoverflow.com/questions/4256107/running-bash-commands-in-python
    def shell(self):
        print('正在生成静态页面并上传至Github，请稍等...')
        os.chdir(self.rootdir)
        command = 'hexo g -d'
        process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        if output:
            print('[output]: \n%s' % output.decode('utf-8'))
        if error:
            print('[error]: \n%s' % error.decode('utf-8'))

    
    # 删除./source/_posts下的所有文章
    # rm失效？here: https://stackoverflow.com/a/31977891
    def delete(self):
        print('正在删除./source/_posts下的所有文章，以防typecho中删除的文章仍然存在于hexo中...')
        command = 'rm -rf %s/source/_posts/*' % self.rootdir
        subprocess.call(command, shell=True)



if __name__ == '__main__':
    r = GO()
