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
# if token and message 0 exit script
if (len(token + messageID) == 0):
    print(f"Please add token & message id")
    exit()
else:
    pass

def getPort():
    global last_line
    #global ngrok_port
    f = open('/var/log/ngrok/ngrok.log', 'r')
    ngrok_port = re.findall("\d.tcp.\w\w.ngrok.io:.{5}", f.read(), re.DOTALL) # Regex for find ngrok.io pattern
    last_line = ngrok_port[-1]
    return last_line

def sendMessages():
    messages = f"""Ngrok New Tunnel: ✅✅✅
<code>{last_line}</code> """
    url_encode = urllib.parse.quote_plus(str(messages))
    print("Send this messages to telegram\n",messages)
    response = requests.post(f"https://api.telegram.org/bot{token}/sendMessage?chat_id={messageID}&text={url_encode}&parse_mode={typeText}", headers=headers)
    print(response.text)


if __name__ == "__main__":
    getPort()
    sendMessages()
