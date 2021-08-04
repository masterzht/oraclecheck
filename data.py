#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Time    : 2021/1/12 下午3:49
# @Author  : yaochong/Chongzi
# @FileName: data.py
# @Software: PyCharm
# @Blog    ：https://github.com/yaochong-06/ ; http://blog.itpub.net/29990276

import cx_Oracle
import os
import paramiko


# 返回Oracle sql脚本内容
def get_sqltext(filename):
    try:
        file_f = open('static/sqlfile/Oracle/' + filename + '.sql', 'r')
        file_contents = file_f.read()
        file_f.close()
    except Exception as re:
        print(re)
    return file_contents


# 删除文件最后一行
def remove_last_line(s):
    return s[:s.rfind('\n')]


def command_local(cmd):
    # 返回结果
    out = os.popen(cmd, 'r', 100).read()
    return out


def command(server_id, server_user, server_password, server_port, cmd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        # 跳过了远程连接中选择‘是’的环节,
        ssh.connect(server_id, server_port, server_user, server_password)
        stdin, stdout, stderr = ssh.exec_command(cmd)
        # 返回结果
        out = str(stdout.read(), 'utf-8')
        return out
    except Exception as re:
        print(f"请确认主机{server_id}、端口是否连通{server_port}...")
        print(re)
    finally:
        ssh.close()


def login_ssh(server_id, server_user, server_password, server_port, scripts):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        # 跳过了远程连接中选择‘是’的环节,
        ssh.connect(server_id, server_port, server_user, server_password)
        stdin, stdout, stderr = ssh.exec_command(scripts)
        # 返回结果
        out = str(stdout.read(), 'utf-8')
        return out
    except Exception as re:
        print(f"请确认主机{server_id}、端口是否连通{server_port}...")
        print(re)
    finally:
        ssh.close()


def get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password, oracle_port,
            service_name, sqlfile):
    try:

        url = f"""{server_id}:{oracle_port}/{service_name}"""
        # 创建连接
        connection = cx_Oracle.connect(oracle_user, oracle_password, url)
        cur = connection.cursor()
        sql_text = get_sqltext(sqlfile)
        cur.execute(sql_text)

        res = list(cur.fetchall())
        res.sort()
    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前Oracle用户名:{oracle_user}、密码:{oracle_password}、IP:{server_id}、端口:{oracle_port}等信息是否正确")
        print(f"{sql_text}...")

    finally:
        cur.close()
        connection.close()
        return res


def get_all_nosort(server_id, server_user, server_password, server_port, oracle_user, oracle_password, oracle_port,
                   service_name, sqlfile):
    try:
        url = f"""{server_id}:{oracle_port}/{service_name}"""
        # 创建连接
        connection = cx_Oracle.connect(oracle_user, oracle_password, url)
        cur = connection.cursor()

        sql_text = get_sqltext(sqlfile)
        cur.execute(sql_text)
        res = list(cur.fetchall())
    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前Oracle用户名:{oracle_user}、密码:{oracle_password}、IP:{server_id}、端口:{oracle_port}等信息是否正确")
        print(f"{sql_text}...")
    finally:
        # 关闭游标
        cur.close()
        cur.close()
        return res


# 获取Oracle执行结果，使用cx_Oracle方式
def get_one(server_id, server_user, server_password, server_port, oracle_user, oracle_password, oracle_port,
            service_name, sqlfile):
    try:
        url = f"""{server_id}:{oracle_port}/{service_name}"""
        # 创建连接
        connection = cx_Oracle.connect(oracle_user, oracle_password, url)
        cur = connection.cursor()

        sql_text = get_sqltext(sqlfile)
        # 执行SQL，并返回收影响行数
        cur.execute(sql_text)
        res = cur.fetchone()[0]
    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前Oracle用户名:{oracle_user}、密码:{oracle_password}、IP:{server_id}、端口:{oracle_port}等信息是否正确")
        print(f"{sql_text}...")
    finally:
        # 关闭游标和连接
        cur.close()
        connection.close()
        return res


# 删除文件最后一行
def remove_last_line(s):
    return s[:s.rfind('\n')]


# 获取Oracle执行结果，使用cx_Oracle方式
def get_oracle_result(server_id, server_user, server_password, server_port, oracle_user, oracle_password, oracle_port,
                      service_name, sqlfile):
    try:
        url = f"""{server_id}:{oracle_port}/{service_name}"""
        # 建立数据库链接
        connection = cx_Oracle.connect(oracle_user, oracle_password, url)
        cur = connection.cursor()
        sql_text = get_sqltext(sqlfile)
        print(sql_text)
    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前Oracle用户名:{oracle_user}、密码:{oracle_password}、IP:{server_id}、端口:{oracle_port}等信息是否正确")
        print(f"{sql_text}...")

        # 查询sql
    try:
        rows = cur.execute(sql_text)
        # 获得当前sql的列名
        title = [i[0] for i in cur.description]

        result_list = []
        for row in rows:
            # 生成二维列表
            result_list.append(row)

        # 将二维嵌套列表[['name','age'],['tom','11']]转换为列表包含字典[{'name':'tom','age':'11'}]
        list_oracle_result_dict = []
        for i in result_list:
            tmp_dict = dict(zip(title, i))
            list_oracle_result_dict.append(tmp_dict)

        return list_oracle_result_dict

    except Exception as re:
        print(re)
    finally:
        cur.close()
        connection.close()


def get_remote_info(server_id, server_user, server_password, server_port, oracle_user, oracle_password, oracle_port,
                   service_name, sqlfile):
    db_info = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password, oracle_port,
                      service_name, "db_info")
    archive_mode = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                           oracle_port, service_name, "archive_mode")
    instance_info = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                            oracle_port, service_name, "instance_info")
    memory_info = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                          oracle_port, service_name, "memory_info")
    db_space = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password, oracle_port,
                       service_name, "db_space")
    db_disk_group = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                            oracle_port, service_name, "db_disk_group")
    user_expire_days = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                               oracle_port, service_name, "user_expire_days")
    backup_info = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                          oracle_port, service_name, "backup_info")
    db_top_activity = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                              oracle_port, service_name, "db_top_activity")
    index_no_foreignkey = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                                  oracle_port, service_name, "index_no_foreignkey")
    big_table_no_index = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                                 oracle_port, service_name, "big_table_no_index")
    database_patch = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                             oracle_port, service_name, "database_patch")
    block_corruption = get_all(server_id, server_user, server_password, server_port, oracle_user, oracle_password,
                               oracle_port, service_name, "block_corruption")

    return db_info, archive_mode, instance_info, memory_info, db_space, db_disk_group, user_expire_days, backup_info, db_top_activity, index_no_foreignkey, big_table_no_index, database_patch, block_corruption


# 获取Oracle执行结果,sqlplus方式
def get_oracle_local_result(oracle_home, sqlplus_path, file_name):
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


def get_local_one(oracle_home, sqlplus_path, file_name):
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


def get_local_all(oracle_home, sqlplus_path, file_name):
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
                result_list.append(re.replace('\t', '').strip().replace('db_check_', '').split('|'))
              #[20210720 modify] result_list.append(re.replace('\t', '').strip().replace(' ', '').replace('db_check_', '').split('|'))
    except Exception as re:
        print(re)
        print(f"连接创建失败,请检查当前oracle_home:{oracle_home}、sqlplus绝对路径：{sqlplus_path}信息是否正确")
        print(f"{file_name}.sql")
    finally:
        return result_list[1:]


def get_local_info(oracle_home, sqlplus_path):
    # 1.5 db_info
    db_info = get_local_all(oracle_home, sqlplus_path, "db_info")
    # 1.6 db_parameter
    db_parameter = get_local_all(oracle_home, sqlplus_path, "db_parameter")
    # 2.1 resource limit
    resource_limit = get_local_all(oracle_home, sqlplus_path, "resource_limit")
    # 2.2 db_load 负载
    db_load = get_local_all(oracle_home, sqlplus_path, "db_load")
    # 3.1 db_disk_group 磁盘组
    db_disk_group = get_local_all(oracle_home, sqlplus_path, "db_disk_group")

    # 3.2 db_space 表空间
    db_space = get_local_all(oracle_home, sqlplus_path, "db_space")

    # 3.4 redo 日志文件的大小和配置
    redo = get_local_all(oracle_home, sqlplus_path, "redo")

    # 3.5 日志切换频率
    log_frequency = get_local_all(oracle_home, sqlplus_path, "log_frequency")

    # 3.6 闪回
    db_recovery = get_local_all(oracle_home, sqlplus_path, "db_recovery")

    # 3.7
    archive_mode = get_local_all(oracle_home, sqlplus_path, "archive_mode")

    dba_privs = get_local_all(oracle_home, sqlplus_path, "dba_privs")

    # 5.11 数据库补丁信息
    database_patch = get_local_all(oracle_home, sqlplus_path, "database_patch")

    # 6.1
    sga = get_local_all(oracle_home, sqlplus_path, "sga")
    # 6.2 load profile
    load_profile = get_local_all(oracle_home, sqlplus_path, "load_profile")
    # 6.3 time model
    time_model = get_local_all(oracle_home, sqlplus_path, "time_model")
    # 6.6 segments by logical reads
    segments_by_logical_reads = get_local_all(oracle_home, sqlplus_path, "segments_by_logical_reads")
    # 6.7
    segments_by_physical_reads = get_local_all(oracle_home, sqlplus_path, "segments_by_physical_reads")

    # 6.11
    sql_ordered_by_reads = get_local_all(oracle_home, sqlplus_path, "sql_ordered_by_reads")
    # 6.12db_top_activity
    db_top_activity = get_local_all(oracle_home, sqlplus_path, "db_top_activity")

    # 7.1 backup_info
    backup_info = get_local_all(oracle_home, sqlplus_path, "backup_info")

    instance_info = get_local_all(oracle_home, sqlplus_path, "instance_info")
    memory_info = get_local_all(oracle_home, sqlplus_path, "memory_info")

    user_expire_days = get_local_all(oracle_home, sqlplus_path, "user_expire_days")
    index_no_foreignkey = get_local_all(oracle_home, sqlplus_path, "index_no_foreignkey")
    big_table_no_index = get_local_all(oracle_home, sqlplus_path, "big_table_no_index")
    block_corruption = get_local_all(oracle_home, sqlplus_path, "block_corruption")

    # 告警日志
    alert_check = get_local_all(oracle_home, sqlplus_path, "alert_check")

    return db_info, db_parameter, resource_limit, db_load, db_disk_group, db_space, redo, log_frequency, db_recovery, \
           archive_mode, dba_privs, database_patch, sga, load_profile, time_model, segments_by_logical_reads, segments_by_physical_reads, \
           sql_ordered_by_reads, db_top_activity, backup_info, \
           instance_info, memory_info, user_expire_days, index_no_foreignkey, \
           big_table_no_index, block_corruption, alert_check

