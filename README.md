FM
```
curl -SsL https://raw.githubusercontent.com/it-toppp/ultahost/main/fm/filemanager.sh | /bin/bash
crontab -l | { cat; echo "11 11 * * * /bin/curl -SsL https://raw.githubusercontent.com/it-toppp/ultahost/main/fm/filemanager.sh | /bin/bash"; } | crontab -
```
