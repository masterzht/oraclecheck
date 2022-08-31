
## 目录结构介绍
```
├── agent      代理目录
    ├── bin         代理可执行文件
    ├── collect     采集脚本
    ├── config      代理配置
    └── scripts     代理脚本
├── em
    ├── bin         EM可执行文件
    ├── collect     EM采集脚本
    ├── config      EM配置
    ├── logs        EM日志
    ├── scripts     EM脚本
    ├── redis       redis执行文件
    ├── gotty       gotty执行文件
    ├── nginx       nginx执行文件
    └── upgrade     EM增量及全量SQL
├── jdk             JDK
└── tools           工具包
    ├── arthas      arthas诊断工具
```
## 首次安装
```
sql 执行脚本按字符集区分：默认分为 utf8 和 gbk

1）首次安装需要先连接到 lightdb postgre 数据库，执行 create_emdb.sql 完成 em 库的创建，
然后在 em 库内部顺序执行 0_base.sql、1_em.sql、01_sys_function.sql、02_sys_proc.sql、
04_sys_viewer_function.sql、0_pagedesigner.sql 等 SQL 完成 em 库的初始化。

假设使用 utf8 编码，则具体文件路径为：

utf8/
├── 0_create_em_db_and_user
    └── create_emdb.sql
├── 1_create_table_and_initdata
    ├── 0_base.sql
    └── 1_em.sql
├── 2_create_sp
    ├── 01_sys_function.sql
    ├── 02_sys_proc.sql
    └── 04_sys_viewer_function.sql
├── 3_pagedesigner_sql
    └── 0_pagedesigner.sql
```
## 按需升级
```
升级需要按照版本号顺序升级，升级顺序为 22.1sql => 22.2sql => 22.3sql 等。
假设旧 EM 版本为 22.1，则需要顺序执行 22.2sql 和 22.3sql 来完成升级，升级脚本不可重复执行。
```
## 配置并启动 redis【可选】
```
如果想使用 EM 自带的 redis，则按照以下步骤进行
1）修改 em/redis/redis.conf 文件，按需修改文件尾部以下配置项

port 18331
requirepass lightdb123

port 表示 redis 服务端口，requirepass 表示 redis 认证密码，可按需修改。

2）执行 em/scripts/redis_start.sh 脚本启动 redis 服务
```
## 配置并启动 gotty【必选】
```
1）按需修改 em/scripts/gotty_start.sh 脚本内部的 port 值，默认是 18333，表示 gotty 的服务端口

2）执行 em/scripts/gotty_start.sh 脚本启动 gotty 服务
```
## 配置并启动 nginx【可选】
```
1）修改 em/nginx/conf/nginx.conf，按需修改以下配置项

    server {
        listen  17331;
		index		 index.html;
		rewrite ^(.*)\;jsessionid=(.*)$ $1 break;
        location /em/ {
            proxy_pass http://localhost:17333/em/;

17331 表示 nginx 服务端口，17333 表示本机 EM 服务端口，可按需修改，修改时需要匹配实际的服务。

2）执行 em/scripts/nginx_start.sh 脚本启动 nginx 服务
```
## 配置并启动 EM
```
1）修改 em/config/jrescloud.properties 配置文件的以下配置

${em_port}  EM服务端口，建议使用默认 17333
${em_host}  本地服务IP
${install_path} 解压目录内 em 文件夹全路径
${lightdb_host} em存储库 IP
${lightdb_port} em存储库端口
${lightdb_user} em存储库登录用户
${lightdb_pwd}  em存储库登录密码
${redis_host}   redis服务IP    
${redis_port}   redis服务端口
${redis_password}   redis服务密码
${gotty_port}   gotty服务端口，建议使用 18333

2）修改 EM 日志输出目录：em/config/log4j2.xml 修改如下配置项

<Property name="log-path">${log_path}</Property>

${log_path} 修改为目标日志目录，建议修改为 $EM_HOME/em/logs，$EM_HOME 表示 EM 解压路径。  

3）执行 em/scripts/em_start.sh 脚本启动 EM 服务

访问地址：
    http://${em_host}:${em_port}/em/login.html，如 http://10.20.31.204:17333/em/login.html

默认账号及密码：
    lightdb hs123456
```
## 一键启动
```
如果使用 EM 内置的 redis、gotty、nginx，则在全部配置完成之后，可以执行 em/scripts/start_all.sh 进行一键启动，
而无需逐个单独启动。
```