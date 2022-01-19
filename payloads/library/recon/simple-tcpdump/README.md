- Install following packages : ``` coreutils-timeout zip ```
- Refer to this payload to install package https://github.com/julesbozouklian/shark_jack_payload/blob/main/payload/util/install_package.sh
- Or SSH to the Shark jack and use following command : ``` opkg install coreutils-timeout zip ```


- For the mail refer to this :
- Install following packages : ``` msmtp mutt ```
- Refer to this payload to install package https://github.com/julesbozouklian/shark_jack_payload/blob/main/payload/util/install_package.sh
- Or SSH to the Shark jack and use following command : ``` opkg install msmtp mutt ```

- Edit the ``` /etc/msmtprc ``` file
```
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account 	gmail
auth 		plain
host 		smtp.gmail.com
port 		587
from 		USER@gmail.com
user 		USER@gmail.com
password 	PASSWORD

account default : gmail

```

- Edit the ``` nano ~/.muttrc ```
```
set sendmail="/usr/bin/msmtp"
set use_from=yes
set realname="SHARK JACK"
set from=USER@gmail.com
set envelope_from=yes
```

#### GMAIL
If you use GMAIL, be sure to enable the "Allow less secure applications" setting  
https://support.google.com/accounts/answer/6010255
