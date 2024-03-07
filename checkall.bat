python -c "import pandas as pd; from configfile import *; SCHTASKS /CREATE /TN "MTRarchive" /TR C:/test/log_arch.bat /SC daily /mo str(log_date) /F ; data= pd.read_csv(data_path); print( data['user id']); print(data['serial']);"
pause
