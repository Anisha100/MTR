python -c "import pandas as pd; from configfile import *; import os; print('Tenant ID= '+tenant_id) ; print('Client ID= '+client_id); print('Client Secret= '+client_secret);
print('Log File Path= '+log_file_path ); print(Image File Path= '+image_file_path); print('Data Path= '+data_path); print('Delay Time= '+delay_time); print('Use service= '+use_service); print('Log Date= 'log_date);
os.system('SCHTASKS /CREATE /TN MTRarchive /TR C:/test/log_arch.bat /SC daily /mo '+ str(log_date) +' /F') ; data= pd.read_csv(data_path); print( data['user id']); print(data['serial']);"
pause
