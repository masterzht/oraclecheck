#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Time    : 2021/1/12 下午3:49
# @Author  : yaochong/Chongzi
# @FileName: doc.py
# @Software: PyCharm
# @Blog    ：https://github.com/yaochong-06/ ; http://blog.itpub.net/29990276
from docxtpl import DocxTemplate
from data import get_info,remove_last_line,command,get_one,get_oracle_result
import time
'''
生成Oracle巡检doc文档
'''
current_time = time.strftime('%Y-%m-%d %H:%M:%S')
check_time = time.strftime('%Y-%m-%d')

'''
传入所有的变量
'''
