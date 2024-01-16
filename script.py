import os
os.system('python -m pip install pywinusb pandas tk pillow pywin32 psutil requests')
from time import sleep
from msvcrt import kbhit
from configfile import *
import pywinusb.hid as hid
import threading
from tkinter import *
from tkinter import ttk
import tkinter
from PIL import Image, ImageTk
import pandas as pd
import time
import sys
import time
import win32evtlog
import win32evtlogutil
import requests
import datetime

def is_idle():
	global dispname
	sleep(1)
	url='https://login.microsoftonline.com/'+tenant_id+'/oauth2/v2.0/token'
	header ={}
	header['Content-Type']= 'application/x-www-form-urlencoded'
	data={}
	data['client_id']=client_id
	data['scope']='https://graph.microsoft.com/.default'
	data['client_secret']=client_secret
	data['grant_type']='client_credentials'
	x=requests.post(url,headers=header,data=data)
	y=x.json()
	tok=(y["access_token"])
	url='https://graph.microsoft.com/beta/teamwork/devices/'+device_id
	header={}
	data={}
	header['Authorization']='Bearer'+' '+tok
	z=requests.get(url,headers=header,data=data)
	a=z.json()
	#print(a)
	state=a['activityState']
	dispname=a['hardwareDetail']['serialNumber']
	#print(state)
	return state=='idle'

def events(message):
	DUMMY_EVT_APP_NAME = "Authentication request "
	DUMMY_EVT_ID = 7040  
	DUMMY_EVT_CATEG = 9876
	DUMMY_EVT_STRS = [message]
	DUMMY_EVT_DATA = message.encode()
	win32evtlogutil.ReportEvent(DUMMY_EVT_APP_NAME, DUMMY_EVT_ID, eventCategory=DUMMY_EVT_CATEG, eventType=win32evtlog.EVENTLOG_WARNING_TYPE, strings=DUMMY_EVT_STRS,data=DUMMY_EVT_DATA)

def validcheck(val):
	global dispname
	try:
		val=str(val)
		df=pd.read_csv(data_path)
		my_df=df.query("serial=="+val)
		x=my_df['user id'].values[0]
		#t1=threading.Thread(target=pop,name='t1',args=(str(x),val))
		#t1.start()
		destroy_window()
		events(f'The User Id is: {x} The Serial No is: {val}')
		write_log(str(datetime.datetime.now()) +" SUCCESS on Device Sl No "+ dispname+" with YubiKey "+val+" by UserID "+str(x))

		return True
	except Exception as e :
		print(e)
		x="No User Id found"
		events(f'Authentication failed for {val}')
		write_log(str(datetime.datetime.now()) +" FAILED on Device Sl No "+ dispname+" with YubiKey "+val)
		return False

def write_log(stmt):
	f=open(log_file_path,"a")
	f.write(stmt+"\n")
	f.close()	

def setup():
	global flag
	global desttime
	desttime=0
	flag=False
	window()
	destroy_window()
	
def destroy_window():
	global root1
	global flag
	global desttime
	desttime=time.time()
	flag=False
	#t8=threading.Thread(target=team_start,name='t8')
	#t8.start()
	root1.withdraw()


def exit_window(e):
        write_log(str(datetime.datetime.now()) +" DEBUG on "+ device_id+" by pressing ESC on Keyboard")
        destroy_window()
		
def lockup():
	global flag
	global desttime
	while use_service:
		if not flag:
			currtime=time.time()
			if currtime-desttime>delay_time and is_idle():
				show_window()
		
def show_window():
	global root1
	global flag
	if is_idle():
		flag=True
		root1.deiconify()

def window():
	global root1
	root1 = Tk()
	root1.attributes('-fullscreen',True)
	root1.attributes('-topmost',True)
	root1.attributes('-alpha',0.4)
	image1=Image.open(image_file_path)
	image1=image1.resize((root1.winfo_screenwidth(),root1.winfo_screenheight()))
	test=	ImageTk.PhotoImage(image1)
	label1=tkinter.Label(image=test)
	label1.image=test
	label1.place(x=0,y=0)
	root1.bind('<Escape>',exit_window)
	root1.mainloop()

def sample_handler(data):
    data=data[10:18]
    slno=int(bytes(data).decode())
    print(slno)
    validcheck(slno)

def raw_test():	
    all_hids = hid.find_all_hid_devices()
    if all_hids:
        while True:
            index_option="0"
            for index, device in enumerate(all_hids):
                device_name = str("{0.vendor_name} {0.product_name}" \
                        "(vID=0x{1:04x}, pID=0x{2:04x})"\
                        "".format(device, device.vendor_id, device.product_id))
                device_name=device_name.lower()              
                if 'baltech' in device_name.lower() or 'kofax' in device_name.lower():
                    index_option=str(index+1)
                    break
            if index_option.isdigit() and int(index_option) <= len(all_hids):
                break;
        int_option = int(index_option)
        if int_option:
            device = all_hids[int_option-1]
            try:
                device.open()
                device.set_raw_data_handler(sample_handler)
                
                print("Tap Yubikey on reader")
                while device.is_plugged():
                    sleep(0.5)
                return
            finally:
                device.close()
    else:
        print("Device unavailable")
    raw_test()

is_idle()        

if __name__ == '__main__' and use_service:
	sleep(5)
	t2=threading.Thread(target=raw_test,name='t2')
	t2.start()
	t6=threading.Thread(target=setup,name='t6')
	t6.start()
	sleep(3)
	lockup()