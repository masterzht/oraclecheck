
import cx_Oracle
def get_oracle_result():
    try:
        connection = cx_Oracle.connect('SYSTEM', 'Ss8866@123', ':1521/aa')
        cursor = connection.cursor()
        for i in range(1, 10000000):
 
            sql_text = 'delete from test where object_id = :dno' 
            cursor.execute(sql_text, {'dno': i})
            connection.commit()
            print(f"current execution....")
    except Exception as re:
        print(re)
    finally:
        print("end")
        cursor.close()
        connection.close()
get_oracle_result()
