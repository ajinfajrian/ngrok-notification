**Notes: this script only work and already testing on ubuntu-22.04 jammy

### Step for installation:

1. Setup your ngrok token, visit this site: https://dashboard.ngrok.com/get-started/setup

`$ ngrok config add-authtoken <your_token>`

2. Running installation script
 
`$ bash install.sh`

3. Setup telegram chat bot token & chat id

`$ vi /opt/ngrok/main.py`

Add telegram token and chat id:

```
token     = "<telegram bot token>"
messageID = "<chat id>"
```

OR visit this site:
- https://www.alphr.com/find-chat-id-telegram/
- https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token

4. Restart ngrok

`$ sudo systemctl restart ngrok.service ngrok-listener.service`

### Final results:
- ![image](https://user-images.githubusercontent.com/39956298/214226252-acd91a5c-1c2c-4447-8060-63928272177b.png)
