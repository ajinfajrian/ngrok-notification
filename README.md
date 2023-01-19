# ngrok-notification telegram

0. change value from all script with your credentials.

1. installing depedencies requirements
```
pip3 install -r requirements.txt
```

2. copy your ngrok config manifest into your local config.
```bash
$ ngrok config check
$ cp ngrok.yaml $HOME/.config/ngrok/ngrok.yml
```

3. copy ngrok service, and running ngrok service
```bash
$ sudo cp ngrok.service /etc/systemd/system/
$ sudo systemctl daemon-reload && sudo systemctl enable --now ngrok.service
```

4. running bot
```bash
$ python3 main.py
```
