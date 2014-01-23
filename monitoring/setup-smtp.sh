# https://rtcamp.com/tutorials/linux/ubuntu-postfix-gmail-smtp/
#install using "no configuration" option
sudo apt-get update
sudo apt-get install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules

#exit

config="/etc/postfix/main.cf"
sudo echo "relayhost = [smtp.gmail.com]:587" >> $config
sudo echo "smtp_sasl_auth_enable = yes" >> $config
sudo echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> $config
sudo echo "smtp_sasl_security_options = noanonymous" >> $config
sudo echo "smtp_tls_CAfile = /etc/postfix/cacert.pem" >> $config
sudo echo "smtp_use_tls = yes" >> $config

sudo echo "[smtp.gmail.com]:587 denis.step.monitor@gmail.com:denis100" >> /etc/postfix/sasl_passwd

sudo chmod 400 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd

sudo cat /etc/ssl/certs/Thawte_Premium_Server_CA.pem | sudo tee -a /etc/postfix/cacert.pem

sudo /etc/init.d/postfix reload

sudo echo "Test mail from postfix" | mail -s "Test Postfix" denis.step@gmail.com
