#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Time    : 2021/1/12 下午3:49
# @Author  : yaochong/Chongzi
# @FileName: doc.py
# @Software: PyCharm
# @Blog    ：https://github.com/yaochong-06/ ; http://blog.itpub.net/29990276
from docxtpl import DocxTemplate
from data import remove_last_line, get_local_info, command_local
import time

'''
生成Oracle巡检doc文档
'''
current_time = time.strftime('%Y-%m-%d %H:%M:%S')
check_time = time.strftime('%Y-%m-%d')

'''
传入所有的变量
'''


def get_local_doc(company_name, engineer_name, customer_name, customer_name2, oracle_home, sqlplus_path, business_name):
    tpl = DocxTemplate('static/tpl/MC_Oracle_tpl.docx')

    print(f"正在巡检{business_name}系统, 请耐心等待...")

    db_info, db_parameter, resource_limit, db_load, db_disk_group, db_space, redo, log_frequency, \
    db_recovery, archive_mode, load_profile, time_model, segments_by_logical_reads, \
    sql_ordered_by_reads, instance_info, memory_info, \
    user_expire_days, backup_info, db_top_activity, index_no_foreignkey, big_table_no_index, \
    database_patch, block_corruption, alert_check \
        = get_local_info(oracle_home, sqlplus_path)

    os_set = command_local("cat /proc/meminfo |grep -E 'Mem|Cache|Swap|Huge'").replace(":", "").replace("kB", "").split(
        '\n')
    # 1.1 系统内存参数
    os_param = []
    for os in os_set:
        os = [x for x in os.split(' ') if x != '']
        if os != []:
            os[1] = round(int(os[1]) / 1024, 2)
            os_param.append(os)

    # 1.3 系统磁盘空间使用
    fs_set = command_local("df -hP").split('\n')
    space_param = []
    for space in fs_set[1:]:
        space_tmp = space.split(' ')
        space = [x for x in space_tmp if x != ''][0:6]
        if space != []:
            space[4] = int(space[4].replace('%', ''))
            space_param.append(space)

    context = {'company_name': company_name,
               'engineer_name': engineer_name,
               'business_name': business_name,
               'c_name': customer_name,
               'c_name2': customer_name2,
               'check_time': check_time,
               # 1.1 系统基础信息
               'release': remove_last_line(command_local('cat /etc/redhat-release')),
               'hostname': remove_last_line(command_local('hostname')),
               'ipfrag_low': remove_last_line(command_local('cat /proc/sys/net/ipv4/ipfrag_low_thresh')),
               'ipfrag_high': remove_last_line(command_local('cat /proc/sys/net/ipv4/ipfrag_high_thresh')),

               # 1.2 系统内存参数
               'os_param': os_param,

               # 1.3 系统CPU参数
               # 物理CPU个数
               'p_cpu_num': remove_last_line(command_local("cat /proc/cpuinfo |grep 'physical id'|sort |uniq|wc -l")),
               # 逻辑CPU个数
               'l_cpu_num': remove_last_line(command_local("cat /proc/cpuinfo |grep 'processor'|wc -l")),
               # CPU核心数
               'cpu_cores': remove_last_line(command_local("cat /proc/cpuinfo |grep 'cores'|uniq|awk '{print $4}'")),
               # 每个物理CPU的核数
               'core_per_p': remove_last_line(command_local("grep 'core id' /proc/cpuinfo | sort -u | wc -l")),
               # CPU 主频
               'cpu_clock_speed': remove_last_line(
                   command_local("cat /proc/cpuinfo | grep MHz | uniq | awk -F: '{print $2}'")),
               # 1.4 系统磁盘空间使用
               'space_param': space_param,
               # 1.5 db info
               'db_info': db_info,
               # 1.6 db parameter
               'db_parameter': db_parameter,
               # 2.1 resource limit
               'resource_limit': resource_limit,
               # 2.2 db_load
               'db_load': db_load,
               # 3.1 db
               'db_disk_group': db_disk_group,
               # 3.2 db_space 表空间
               'db_space': db_space,
               # 3.4 日志文件大小和配置
               'redo': redo,
               # 3.5 日志切换频率
               'log_frequency': log_frequency,
               # 3.6 闪回区
               'db_recovery': db_recovery,

               # 6.2 load profile
               'load_profile': load_profile,
               # 6.3 time model
               'time_model': time_model,

               # segments by logical reads
               'segments_by_logical_reads': segments_by_logical_reads,
               # segments by logical reads

               # 6.11
               'sql_ordered_by_reads': sql_ordered_by_reads,

               # 8.0 错误日志检查
               'alert_check': alert_check,
               }

    tpl.render(context)
    tpl.save(f'./{business_name}巡检报告{current_time}.docx')


get_local_doc('杭州woqu科技', '姚崇', '王骏', '王天田', '/u01/app/oracle/product/11.2.0/db_1',
              '/u01/app/oracle/product/11.2.0/db_1/bin/sqlplus', 'ODS系统')
