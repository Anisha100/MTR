tenant_id = '69123506-e623-429a-a461-74482242e5f2'
client_id = 'eba80889-1602-4c06-b8f2-6b63445d88d2'
client_secret = 'OUH8Q~RopgqKTjwf3-U3ChkK5aEgbcQl62aFNcDc'
device_id = '6c037821-003c-4389-b59a-4499cefa22f8'
log_file_path = 'C:/test/log.txt'
image_file_path = 'C:/test/img.png'
data_path = 'C:/test/userlist.csv'
delay_time = 30
use_service=True
log_date=7
os.system("SCHTASKS /CREATE /TN "MTRarchive" /TR "C:/test/log_arch.bat" /SC daily /mo "+str(log_date)+" /d WED /F ")
