#!/bin/bash

addFile(){
	sudo apt install acl python3-pip -y >/dev/null
	pip3 install regex urllib3 >/dev/null
	sudo mkdir -p /opt/ngrok/ && mkdir -p /home/$USER/.config/ngrok/
	sudo setfacl -m user:$USER:rwx -R /opt/ngrok/
	cat << EOF | sudo tee /opt/ngrok/main.py >/dev/null
#!/usr/bin/python3

import requests
import re
import urllib

# global variable
token     = ""
messageID = ""

typeText  = "HTML" # Markdown / HTML, default=Markdown but html more smooth than markdown
headers = {
    "accept": "application/json",
    "content-type": "application/json",
    "User-Agent": "Mozilla/5.0 (Linux; Android 5.0; SAMSUNG-SM-N900A Build/LRX21V)",
}

if (len(token + messageID) == 0):
    print(f"Please add token & message id")
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
    messages = f"""New Tunnel: ✅✅✅
<code>ssh {hostname} -p {port}</code> """
    url_encode = urllib.parse.quote_plus(str(messages))
    print("Send this messages to telegram\n",messages)
    response = requests.post(f"https://api.telegram.org/bot{token}/sendMessage?chat_id={messageID}&text={url_encode}&parse_mode={typeText}", headers=headers)
    print(response.text)


if __name__ == "__main__":
    getPort()
    sendMessages()
EOF
	cat << EOF | sudo tee /etc/systemd/system/ngrok.service >/dev/null
[Unit]
Description=ngrok
After=network.target

[Service]
ExecStart=ngrok start --config=/home/$USER/.config/ngrok/ngrok.yml ssh-access
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
After=ngrok.service

[Service]
Type=oneshot
# Wait 2 seconds before the unit starts.
ExecStartPre=/bin/sleep 2
ExecStart=/usr/bin/python3 /opt/ngrok/main.py
RemainAfterExit=yes

[Install]
# when service is enable, forces this service to start when ngrok is started
WantedBy=ngrok.service
EOF
    cat << EOF | tee -a /home/$USER/.config/ngrok/ngrok.yml >/dev/null
region: ap
log_level: info
log_format: logfmt
log: /var/log/ngrok/ngrok.log
tunnels:
  ssh-access:
    addr: 22
    proto: tcp
EOF
}

ngrokChecking(){
	sudo mkdir -p /var/log/ngrok/ && sudo touch /var/log/ngrok/ngrok.log
    ngrokInstallation=$(dpkg --get-selections | grep -o ngrok)
    if [[ $ngrokInstallation == "ngrok" ]]
    then
        :
    else
        echo "ngrok is not installed, try to installing"
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install -y ngrok
    fi
}

mkdir -p /home/$USER/.config/ngrok/
tokenChecking=/home/$USER/.config/ngrok/ngrok.yml
if [[ -f "$tokenChecking" ]]
then
	echo "===== Setup File ====="
	sed -i '{/region:/,+8d}' /home/$USER/.config/ngrok/ngrok.yml
	addFile
	echo "===== Check & Install Ngrok Service ====="
	ngrokChecking
	sudo systemctl daemon-reload && sudo systemctl enable --now ngrok.service ngrok-listener.service
	sudo chown $USER:$USER /var/log/ngrok/ngrok.log
else
	ngrokChecking
	echo "Plase add your ngrok token. visit: https://dashboard.ngrok.com/get-started/setup"
	echo "example: ngrok config add-authtoken xXx"
	exit 0
fi
echo "===== Ngrok Installed ====="
