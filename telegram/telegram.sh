#!/bin/bash

# Run
# bash <(wget --cache=off -q -O - https://github.com/ghzserg/zmod_ff5m/raw/refs/heads/1.5/telegram/telegram.sh)

apt update 
apt upgrade -y
apt install docker.io docker-compose docker sudo apparmor -y

useradd -m -G docker tbot
chsh tbot -s /bin/bash

systemctl enable docker
systemctl restart docker

cd ~tbot
cat > install.sh <<EOF
#!/bin/bash
cd
read -p "Введите название каталога где будет хранится бот [bot1]: " bot_name
if [ "\${bot_name}" == "" ]; then bot_name="bot1"; fi
mkdir -p \${bot_name}
cd \${bot_name}
echo "Бот установлен в каталог $(pwd)"
mkdir -p config log timelapse_finished timelapse 
wget --cache=off -q -O ../ff5m.sh https://raw.githubusercontent.com/ghzserg/ff5m/refs/heads/main/telegram/ff5m.sh
chmod +x ../ff5m.sh
wget --cache=off -q -O docker-compose.yml https://raw.githubusercontent.com/ghzserg/ff5m/refs/heads/main/telegram/docker-compose.yml
wget --cache=off -q -O config/telegram.conf https://github.com/ghzserg/ff5m/raw/refs/heads/main/telegram/telegram.conf
chmod 777 config log timelapse_finished timelapse

echo "1. Идете к https://t.me/BotFather
2. /newbot
3. Вводите любое имя, которое вам нравится
4. Вводите имя бота например ff5msuper_bot - обязательно _bot в конце.
5. Получаете длинный ID - его нужно будет прописать в настройках бота в параметр bot_token"

read  -p "Введите bot_token: " bot_token

sed -i "s|bot_token: 1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA|bot_token: \${bot_token}|" config/telegram.conf
docker-compose up -d

echo "Заходите в своего бота, через телеграм
Он напишет. Unauthorized access detected with chat_id:
Впишите полученное числю в chat_id"

read -p "Введите chat_id: " chat_id 
docker-compose down
sed -i "s|chat_id: 111111111|chat_id: \${chat_id}|" config/telegram.conf 
docker-compose up -d
read -p "Нужно создать еще одного бота? [y/N]: " vopros
if [ "\${vopros}" == "y" ] || [ "\${vopros}" == "Y" ]; then cd; ./install.sh; fi
EOF
chmod +x install.sh
su - tbot ./install.sh
