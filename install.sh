#!/bin/bash

osChecking(){
    os_name=$(cat /etc/os-release | awk -F '=' '/^NAME/{print $2}' | tr -d '"')
    if [ "$os_name" == "Ubuntu" ]
    then
            echo "===== System is ubuntu ====="
            echo "Installing depedencies ..."
            sudo apt install -y acl python3-pip >/dev/null
    elif [ "$os_name" == "AlmaLinux" ] || [ "$os_name" == "CentOS" ] || [ "$os_name" == "RockyLinux" ] | [ "$os_name" == "Red Hat Enterprise Linux" ]
    then
            echo "===== System is rhel distribution ====="
            echo "Installing depedencies ..."
            sudo dnf install -y acl python3-pip >/dev/null
    else
            echo "your linux distribution is not support"
            exit 1
    fi
}

addFile(){
	pip3 install regex urllib3 >/dev/null
	sudo mkdir -p /opt/ngrok/ && mkdir -p /home/$USER/.config/ngrok/
	sudo setfacl -m user:$USER:rwx -R /opt/ngrok/
	cat << EOF | sudo tee /opt/ngrok/main.py >/dev/null
#!/usr/bin/python3

import requests
import re
import urllib

# global variable
tg_token     = ""
tg_chat_id = ""

tg_format  = "HTML" # Markdown / HTML, default=Markdown but html more smooth than markdown
headers = {
    "accept": "application/json",
    "content-type": "application/json",
    "User-Agent": "Mozilla/5.0 (Linux; Android 5.0; SAMSUNG-SM-N900A Build/LRX21V)",
}

if (len(tg_token + tg_chat_id) == 0):
    print(f"Please add telegram token & chat id")
    exit()
else:
    pass

def getPort():
    global hostname, port
    f = open('/var/log/ngrok/ngrok.log', 'r')
    ngrok_port = re.findall("\d.tcp.\w\w.ngrok.io:.{5}", f.read(), re.DOTALL)[-1] # Regex for find ngrok.io pattern the last list
    hostname, port = ngrok_port.split(":") # separate hostname and port  (:) 0.tcp.ap.ngrok.io:11466
    return hostname, port

def sendMessages():
    messages = f"""New Tunnel: ✅
<code>ssh {hostname} -p {port}</code> """
    url_encode = urllib.parse.quote_plus(str(messages))
    print("Send this messages to telegram\n",messages)
    response = requests.post(f"https://api.telegram.org/bot{tg_token}/sendMessage?chat_id={tg_chat_id}&text={url_encode}&parse_mode={tg_format}", headers=headers)
    print(response.text)


if __name__ == "__main__":
    getPort()
    sendMessages()
EOF
	cat << EOF | sudo tee /etc/systemd/system/ngrok.service >/dev/null
[Unit]
Description=ngrok
After=network.target network-online.target

[Service]
ExecStart=ngrok start --config=/home/$USER/.config/ngrok/ngrok.yml ssh
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
IgnoreSIGPIPE=true
Restart=always
RestartSec=3
Type=simple

[Install]
WantedBy=multi-user.target
EOF
	cat << EOF | sudo tee /etc/systemd/system/ngrok-listener.service >/dev/null
[Unit]
Description=Service for listening ngrok service
# disable this service if ngrok got stop
BindsTo=ngrok.service
# waits to be started before this service is started
After=ngrok.service network.target network-online.target

[Service]
Type=oneshot
# Wait 13 seconds before the unit starts.
ExecStartPre=/bin/sleep 13
ExecStart=/usr/bin/python3 /opt/ngrok/main.py
RemainAfterExit=yes

[Install]
# when service is enable, forces this service to start when ngrok is started
WantedBy=ngrok.service
EOF
    cat << EOF | tee -a /home/$USER/.config/ngrok/ngrok.yml >/dev/null
  log_level: info
  log_format: logfmt
  log: /var/log/ngrok/ngrok.log
endpoints:
  - name: ssh
    url: tcp://
    upstream:
      url: 22
EOF
}

mkdir -p /home/$USER/.config/ngrok/
sudo mkdir -p /var/log/ngrok/ && sudo touch /var/log/ngrok/ngrok.log
tokenChecking=/home/$USER/.config/ngrok/ngrok.yml
if [[ -f "$tokenChecking" ]]
then
    echo "===== OS Checking ====="
    osChecking
	echo "===== Setup File ====="
	sed -i '{/region:/,+8d}' /home/$USER/.config/ngrok/ngrok.yml
	addFile
	echo "===== Check & Install Ngrok Service ====="
	sudo systemctl daemon-reload && sudo systemctl enable --now ngrok.service ngrok-listener.service
	sudo chown $USER:$USER /var/log/ngrok/ngrok.log
else
	echo "Plase add your ngrok token. visit: https://dashboard.ngrok.com/get-started/setup"
	echo "example: ngrok config add-authtoken xXx"
	exit 0
fi
echo "===== Ngrok Installed ====="
echo "===== Don't forget to run your python script on /opt/ngrok/main.py"
