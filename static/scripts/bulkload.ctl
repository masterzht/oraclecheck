#
# import.ctl -- Control file to load CSV input data
#
#    Copyright (c) 2007-2021, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
#
OUTPUT = emp                   # [<schema_name>.]table_name
INPUT = /home/lightdb/emp.txt  # Input data location (absolute path)
TYPE = CSV                            # Input file type
QUOTE = "\""                          # Quoting character
ESCAPE = \                            # Escape character for Quoting
DELIMITER = "|"                       # Delimiter
NULL=""

LIMIT=INFINITE
CHECK_CONSTRAINTS=NO
MULTI_PROCESS = YES
WRITER=DIRECT
ON_DUPLICATE_KEEP=NEW
TRUNCATE=YES