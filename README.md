# VitaliyLedenev_infra
VitaliyLedenev Infra repository
---

# Урок 6.Знакомство с облачной инфраструктурой и облачными сервисами

```
testapp_IP = 51.250.14.14
testapp_port = 9292
```
## Настройка рабочего окружения для работы с Yandex Cloud через YC CLI
* На странице https://cloud.yandex.ru/docs/cli/quickstart выберем  для своей ОС и установим утилиту **yc**:

`curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash`

* согласно руководству https://cloud.yandex.ru/docs/cli/operations/profile/profile-create создаем профиль, подключаемся  к yandex cloud через утилиту yc
* После подключения проверяем, что все ок
```
# текущие настройки
yc config list
# список профилей, какой активный
yc config profile list
# получить настройки конкретного профиля
yc config profile get default
```

## Создадим новый инстанс через yc
```
yc compute instance create \
  —name reddit-app \
  —hostname reddit-app \
  —memory=4 \
  —create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  —network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  —metadata serial-port-enable=1 \
  —ssh-key ~/.ssh/appuser.pub
```


## Самостоятельная работа: создадим файлы для установки и запуска приложения на созданном инстансе
* **install_ruby.sh**
```
#!/bin/sh
sudo apt update && sudo apt upgrade -y
ufw disable
sudo systemctl disable apparmor
sudo apt install -y ruby-full ruby-bundler build-essential
ruby -v
bundler -v
```
* **install_mongodb.sh**
```
#!/bin/sh
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```
* **deploy.sh**
```
#!/bin/sh
sudo apt-get install git -y
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```



---




# 5 Урок. Знакомство с облачной инфраструктурой и облачными сервисами
## Yandex Cloud
```
bastion_IP = 178.154.231.176
someinternalhost_IP = 10.128.0.33
```

• регистрируемся, если не зарегистрированы
• создаём облако **cloud-otus**
• создаём в облаке каталог **infra**
• генерируем ключи для будущих vm
`ssh-keygen -t rsa -f ~/.ssh/appuser -C appuser -P ""`
* создаём 2 виртуальных машины в  зоне доступности ru-central1-a:
	* первую bastion (ext_ip:178.154.231.176, int_ip:10.128.0.6)
	* вторую someinternalhost только с внутренним ip (int_ip:10.128.0.33)
	* при создании машин указываем сгенерированный выше публичный ключ appuser.pub

## Использование ключа и сквозное подключение
* Для использования ключа по всей цепочки серверов за bastion сервером  добавим приватный ключ в агент авторизации:
```
ssh-add ~/.ssh/appuser
ssh -i ~/.ssh/appuser -A appuser@178.154.231.176
```
	• далее проверяем соединение с someinternalhost, пароль не должен быть запрошен и не должно требоваться указывать путь до приватного ключа:
```
ssh 10.128.0.33
appuser@bastion-prod:~$ ssh 10.128.0.33
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@someinternalhost:~$ hostname
someinternalhost
appuser@someinternalhost:~$
```

### Самостоятельное задание
* **способ подключения к someinternalhost в одну команду из рабочего устройства - используем ключ -J**
`ssh -A -J appuser@178.154.231.176 appuser@10.128.0.33`
### Задание со *: Предложить вариант решения для подключения из консоли при помощи команды вида ssh someinternalhost
* **вар1**:
		* добавить в .zshrc или .bash_aliases:
	`alias someinternalhost="ssh -A -J appuser@178.154.231.176 appuser@10.128.0.33"`
* **вар2**
		* добавить в  ~/.ssh/config:
```
Host someinternalhost
  Hostname 10.128.0.33
  IdentityFile  ~/.ssh/appuser
  ForwardAgent yes
  User appuser
  ProxyCommand ssh -W %h:%p -i ~/.ssh/appuser appuser@178.154.231.176
```

* далее для соединения c someinternalhost минуя bastion:
`ssh someinternalhost`
## Создаем VPN-сервер для серверов Yandex.Cloud
• загружаем с и запускаем установку:
```
curl -O https://ip/setupvpn.sh
sudo bash setupvpn.sh
```
* по адресу https://178.154.231.176/setup вводим  setup-key который будет создан сразу из setup-key
* затем генерируем пароль для входа:
`sudo pritunl default-password`
* **Дополнительное задание:** при входе появится окно «Initial Setup» в поле «Lets Encrypt Domain»  впишем свой домен предварительно направленный на ip сервера  178.154.231.176. Pritunl самостоятельно выпустить сертификат и настроит работу через него. Теперь мы можем обращаться к серверу pritunl по адресу:
`https://pritunl.vedm.ru`
* далее создаем пользователя test с PIN 6214157507237678334670591556762, организацию и сервер. Сервер связываем с организацией и запускаем. В настройках пользователя скачиваем ovpn файл и клиент для своей ОС: https://openvpn.net/client-connect-vpn-for-mac-os/
* запускаем скаченный файл ovpn в установленном клиенте, вводим пароль полученный на шаге `pritunl default-password` и pin заданный к пользователю test
* проверяем, что с рабочего устройства можем сразу подключиться к someinternalhost:
```
 ~ % ssh -i ~/.ssh/appuser appuser@10.128.0.33
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@someinternalhost:~$
```
