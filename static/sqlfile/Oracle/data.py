#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Time    : 2021/1/12 下午3:49
# @Author  : yaochong/Chongzi
# @FileName: data.py
# @Software: PyCharm
# @Blog    ：https://github.com/yaochong-06/ ; http://blog.itpub.net/29990276

import os, time, paramiko, datetime
# 删除文件最后一行
def remove_last_line(s):
    return s[:s.rfind('\n')]

# 获取Oracle执行结果,sqlplus方式
def get_oracle_result(oracle_home, sqlplus_path,file_name):
    try:
        res = os.popen(f""" export ORACLE_HOME={oracle_home} && {sqlplus_path} / as sysdba <<EOF
set colsep "|"
set linesize 32767
set pages 20000
@static/sqlfile/Oracle/{file_name}.sql
EOF""", 'r', 100).readlines()

        # 生成二维列表
        result_list = []
        for re in res:
            if re.startswith('db_check_'):
                result_list.append(re.replace('\t', '').strip().replace(' ', '').split('|'))
        # 将二维嵌套列表[['name','age'],['tom','11']]转换为列表包含字典[{'name':'tom','age':'11'}]
        # 取第一行字典
        list_oracle_result_dict = []
        # 判断以下result_list是否为空，也就意味着巡检的sql是否有返回值
        if result_list:
            title = result_list[0]

            for i in result_list:
                tmp_dict = dict(zip(title, i))
            list_oracle_result_dict.append(tmp_dict)
    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前oracle_home:{oracle_home}、sqlplus绝对路径：{sqlplus_path}信息是否正确")
        print(f"{file_name}.sql")
    finally:
        return list_oracle_result_dict

def get_one(oracle_home, sqlplus_path,file_name):
    try:
        res = os.popen(f""" export ORACLE_HOME={oracle_home} && {sqlplus_path} / as sysdba <<EOF
set colsep "|"
set linesize 32767
set pages 20000
@static/sqlfile/Oracle/{file_name}.sql
EOF""", 'r', 100).readlines()

        # 生成二维列表
        result_list = []
        for re in res:
            if re.startswith('db_check_'):
                result_list.append(re.replace('\t', '').strip().replace(' ', '').split('|'))

    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前oracle_home:{oracle_home}、sqlplus绝对路径：{sqlplus_path}信息是否正确")
        print(f"{file_name}.sql")
    finally:
        return result_list[1][1]

"""
获取二维list
"""
def get_all(oracle_home, sqlplus_path,file_name):
    try:
        res = os.popen(f""" export ORACLE_HOME={oracle_home} && {sqlplus_path} / as sysdba <<EOF
set colsep "|"
set linesize 32767
set pages 20000
@static/sqlfile/Oracle/{file_name}.sql
EOF""", 'r', 100).readlines()

        # 生成二维列表
        result_list = []
        for re in res:
            if re.startswith('db_check_'):
                result_list.append(re.replace('\t', '').strip().replace(' ', '').replace('db_check_','').split('|'))

    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前oracle_home:{oracle_home}、sqlplus绝对路径：{sqlplus_path}信息是否正确")
        print(f"{file_name}.sql")
    finally:
        return result_list[1:]

def get_sys_message(sysscripts):
    # 内存
    if sysscripts == 'node_memory_MemAvailable':
        return (os.popen("cat /proc/meminfo |awk '/MemAvailable/{print $2}'", 'r', 100).read())
    elif sysscripts == 'node_memory_MemTotal':
        return (os.popen("cat /proc/meminfo |awk '/MemTotal/{print $2}'", 'r', 100).read())
    elif sysscripts == 'node_memory_MemFree':
        return (os.popen("cat /proc/meminfo | awk '/MemFree/{print $2}'", 'r', 100).read())
    # swap
    elif sysscripts == 'node_memory_SwapTotal':
        return (os.popen("cat /proc/meminfo |awk '/SwapTotal/{print $2}'", 'r', 100).read())
    elif sysscripts == 'node_memory_SwapFree':
        return (os.popen("cat /proc/meminfo |awk '/SwapFree/{print $2}'", 'r', 100).read())
    # load 1 5 15
    elif sysscripts == 'node_load1':
        return (os.popen("cat /proc/loadavg |awk '{print $1}'", 'r', 100).read())
    elif sysscripts == 'node_load5':
        return (os.popen("cat /proc/loadavg |awk '{print $2}'", 'r', 100).read())
    elif sysscripts == 'node_load15':
        return (os.popen("cat /proc/loadavg |awk '{print $3}'", 'r', 100).read())
    # filesystem
    elif sysscripts == 'node_filesystem_size_kb':
        return os.popen("""df -T |awk 'NR>1{print "device:"$1",mountpoint:"$NF","$3}'""", 'r', 100).read()
    elif sysscripts == 'node_filesystem_avail_kb':
        return os.popen("""df |awk 'NR>1{print "device:"$1",mountpoint:"$NF","$4}'""", 'r', 100).read()
    elif sysscripts == 'node_filesystem_files':
        return os.popen("""df -iT |awk 'NR>1{print "device:"$1",fstype:"$2",mountpoint:"$NF","$3}'""", 'r', 100).read()

    elif sysscripts == 'node_filesystem_files_free':
        return os.popen("""df -iT |awk 'NR>1{print "device:"$1",fstype:"$2",mountpoint:"$NF","$5}'""", 'r', 100).read()
    # cpu
    elif sysscripts == 'node_cpu':
        # r取消转义
        return os.popen(
            r"""top -bn 2 -i -c | grep "Cpu(s):" | awk -F: '{print $2}' | tail -1 | sed 's/[\%a-z,]\+/\n/g' | sed 's/ \+//g' | awk 'BEGIN{mode[1]="user";mode[2]="system";mode[3]="nice";mode[4]="idle";mode[5]="i
owait"}NR<=5{printf "cpu:cpus,mode:%s,%s\n",mode[NR],$0}'""",
            'r', 100).read()
    else:
        return ''

def command(cmd):
    # 返回结果
    out = os.popen(cmd,'r',100).read()
    return out

def login_ssh_command(server_id, server_user, server_password, server_port,scripts):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        # 跳过了远程连接中选择‘是’的环节,
        ssh.connect(server_id, server_port, server_user, server_password)
        stdin, stdout, stderr = ssh.exec_command(scripts)
        # 返回结果
        out = str(stdout.read(),'utf-8')
        return out
    except Exception as re:
        print(f"请确认主机{server_id}、端口是否连通{server_port}...")
        print(re)
    finally:
        ssh.close()
