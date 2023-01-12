#!/bin/bash

#===================================================#
# NAME...........:auto_install_moodle.sh            #
# VERSION........:1.12.0                            #
# DESCRIPTION....:Auto Instalação Moodle            #
# CREATE DATE....:28/12/2022                        #
# AUTHOR.........:Ivan da Silva Bispo Junior        #
# MAINTAINER.....:Ivan da Silva Bispo Junior        #
# E-MAIL.........:contato@ivanjr.eti.br             #
# SITE...........:https://ivanjr.eti.br             #
# DISTRO.........:Debian GNU/Linux 11 (Bullseye)    #
# TESTED ON......:Bash 5.1.4                        #
#===================================================#

# Esse Script insalar o Moodle e todas as suas dependencias...
clear
echo "========Informe os dados abaixo========"
echo""
read -p "Digite o nome do usuário do banco de dados: " NOME_USUARIO
read -p "Digite a senha do usuário do banco de dados: " SENHA_USUARIO
read -p "Digite o nome do banco de dados: " NOME_BANCO
read -p "digite o ip do servidor ou (localhost): " IP
clear

echo "confirme se os dados estão corretos"
echo "Nome do usuário do banco de dados: $NOME_USUARIO"
echo "Senha do usuário do banco de dados: $SENHA_USUARIO"
echo "Nome do banco de dados: $NOME_BANCO"
echo "IP do servidor: $IP"
echo""
read -p "Digite (s) para continuar ou (n) para corrigir os dados inseridos: " CONFIRMA
if [ $CONFIRMA = "s" ]; then
    echo "Continuando..."
else
    echo "Corrigindo os dados..."
    sleep 3
    bash SCRIPT_MOODLE.sh
fi

echo -e "Atualizando o sistema..."

apt update && apt upgrade -y

apt install sudo -y

apt install apt-transport-https lsb-release ca-certificates wget -y

clear
NGINX=/etc/nginx/
if [ -d "$NGINX" ]; then
    echo -e "Configurando o nginx..."
    sleep 3
    sed -i 's/#server_tokens/server_tokens/' /etc/nginx/nginx.conf
    systemctl restart nginx
    cp -R /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bkp
    rm -R /etc/nginx/sites-available/default
    touch /etc/nginx/sites-available/default

echo -e "Configurando o nginx..."
sleep 3
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    listen [::]:80;
    server_name "$IP";
    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }
    location ~ /\.ht {
        deny all;
    }
}
EOF
else
    echo -e "Instalando o pacote nginx..."
    sleep 3
    apt-get -y install nginx
    sed -i 's/#server_tokens/server_tokens/' /etc/nginx/nginx.conf
    systemctl restart nginx
    cp -R /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bkp
    rm -R /etc/nginx/sites-available/default
    touch /etc/nginx/sites-available/default

echo -e "Configurando o nginx..."
sleep 3
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    listen [::]:80;
    server_name "$IP";
    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }
    location ~ /\.ht {
        deny all;
    }
}
EOF
fi
clear
POSTGRESQL=/etc/postgresql/
if [ -d "$POSTGRESQL" ]; then
    echo -e "Configurando o postgresql..."
    sleep 3
    echo -e "Criando o banco de dados e o usuário do banco de dados..."
    sleep 3
    sudo sed -i "s/ident/md5/g" /etc/postgresql/13/main/pg_hba.conf
    su postgres -c "psql -c \"CREATE USER $NOME_USUARIO WITH PASSWORD '$SENHA_USUARIO';\""
    su postgres -c "psql -c \"CREATE DATABASE $NOME_BANCO WITH OWNER $NOME_USUARIO;\""
    su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $NOME_BANCO TO $NOME_USUARIO;\""
    clear
    echo -e "Banco de dados criado com sucesso!"
    sleep 3
    clear
else
    clear
    echo -e "Instalando o pacote postgresql..."
    sleep 3
    apt-get -y install postgresql
    echo -e "Criando o banco de dados e o usuário do banco de dados..."
    sleep 3
    sudo sed -i "s/ident/md5/g" /etc/postgresql/13/main/pg_hba.conf
    su postgres -c "psql -c \"CREATE USER $NOME_USUARIO WITH PASSWORD '$SENHA_USUARIO';\""
    su postgres -c "psql -c \"CREATE DATABASE $NOME_BANCO WITH OWNER $NOME_USUARIO;\""
    su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $NOME_BANCO TO $NOME_USUARIO;\""
    clear
    echo -e "Banco de dados criado com sucesso!"
    sleep 3
fi
clear
PHP=/etc/php/
if [ -d "$PHP" ]; then
    clear
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/8.1/fpm/php.ini
    sed -i "s/post_max_size = 8M/post_max_size = 100M/" /etc/php/8.1/fpm/php.ini
    sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/8.1/fpm/php.ini
    sed -i "s/max_input_time = 60/max_input_time = 300/" /etc/php/8.1/fpm/php.ini
    sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/8.1/fpm/php.ini
    sed -i "s/;max_input_vars = 1000/c\max_input_vars = 5000" /etc/php/8.1/fpm/php.ini
    sed -i "s/;date.timezone =/date.timezone = America\/Bahia/" /etc/php/8.1/fpm/php.ini
    sed -i "s/;date.timezone =/date.timezone =America\/Bahia/" /etc/php/8.1/cli/php.ini
    timedatectl set-timezone Etc/UTC
    clear

    sed -i "s/;security.limit_extensions = .php .php3 .php4 .php5 .php7/security.limit_extensions = .php/" /etc/php/8.1/fpm/pool.d/www.conf
else
    echo -e "Instalando o pacote php..."
    sleep 3
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list

    apt update && apt upgrade -y
    sudo apt install php8.1-cli php8.1-curl php8.1-fpm php8.1-gd php8.1-gmp php8.1-phpdbg\
                 php8.1-cgi php8.1-mbstring php8.1-mysql php8.1-snmp php8.1-xml php8.1-zip\
                 php8.1-common php8.1-xml php8.1-xmlrpc php8.1-soap php8.1-intl -y
    clear
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/8.1/fpm/php.ini
    sed -i "s/post_max_size = 8M/post_max_size = 100M/" /etc/php/8.1/fpm/php.ini
    sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/8.1/fpm/php.ini
    sed -i "s/max_input_time = 60/max_input_time = 300/" /etc/php/8.1/fpm/php.ini
    sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/8.1/fpm/php.ini
    sed -i "s/;max_input_vars = 1000/c\max_input_vars = 5000" /etc/php/8.1/fpm/php.ini
    sed -i "s/;date.timezone =/date.timezone = America\/Bahia/" /etc/php/8.1/fpm/php.ini
    sed -i "s/;date.timezone =/date.timezone =America\/Bahia/" /etc/php/8.1/cli/php.ini
    timedatectl set-timezone Etc/UTC
    clear

    sed -i "s/;security.limit_extensions = .php .php3 .php4 .php5 .php7/security.limit_extensions = .php/" /etc/php/8.1/fpm/pool.d/www.conf
fi

service php8.1-fpm restart
service nginx restart

clear
echo -e "Instalando o pacote moodle..."
sleep 3
if [ -d "/var/www/html/moodle" ]; then
    echo -e "O Moodle já está instalado!"
    sleep 3
    exit
else
    echo -e "Instalando o pacote moodle..."
    sleep 3
    apt install wget -y
    cd /tmp
    wget https://download.moodle.org/download.php/direct/stable401/moodle-latest-401.tgz
    tar -xvzf moodle-latest-401.tgz
    cp /tmp/moodle /var/www/html/ -R
    chown www-data.www-data /var/www/html/moodle -R
    chmod 0755 /var/www/html/moodle -R
    mkdir /var/www/moodledata
    chown www-data /var/www/moodledata -R
    chmod 0770 /var/www/moodledata -R
fi

clear
echo "Configurando o crontab"
sleep 3
echo "*/10 * * * * /usr/bin/php /var/www/html/moodle/admin/cli/cron.php > /dev/null" >> /etc/crontab
*/10 * * * * /usr/bin/php /var/www/moodle/admin/cli/cron.php  >/dev/null
clear
echo "Crontab configurado com sucesso!"
sleep 3

echo "Gostaria de instalar complementos do BASH?"
read -p "Digite [S] para sim ou [N] para não: " OPCAO
if [$OPCAO = 's']; then
    sudo apt install bash-completion fzf grc -y
echo '' >> /etc/bash.bashrc
echo '# Autocompletar extra' >> /etc/bash.bashrc
echo 'if ! shopt -oq posix; then' >> /etc/bash.bashrc
echo '  if [ -f /usr/share/bash-completion/bash_completion ]; then' >> /etc/bash.bashrc
echo '    . /usr/share/bash-completion/bash_completion' >> /etc/bash.bashrc
echo '  elif [ -f /etc/bash_completion ]; then' >> /etc/bash.bashrc
echo '    . /etc/bash_completion' >> /etc/bash.bashrc
echo '  fi' >> /etc/bash.bashrc
echo 'fi' >> /etc/bash.bashrc
sed -i 's/"syntax on/syntax on/' /etc/vim/vimrc
sed -i 's/"set background=dark/set background=dark/' /etc/vim/vimrc
cat <<EOF >/root/.vimrc
set showmatch " Mostrar colchetes correspondentes
set ts=4 " Ajuste tab
set sts=4 " Ajuste tab
set sw=4 " Ajuste tab
set autoindent " Ajuste tab
set smartindent " Ajuste tab
set smarttab " Ajuste tab
set expandtab " Ajuste tab
"set number " Mostra numero da linhas
EOF
sed -i "s/# export LS_OPTIONS='--color=auto'/export LS_OPTIONS='--color=auto'/" /root/.bashrc
sed -i 's/# eval "`dircolors`"/eval "`dircolors`"/' /root/.bashrc
sed -i "s/# export LS_OPTIONS='--color=auto'/export LS_OPTIONS='--color=auto'/" /root/.bashrc
sed -i 's/# eval "`dircolors`"/eval "`dircolors`"/' /root/.bashrc
sed -i "s/# alias ls='ls \$LS_OPTIONS'/alias ls='ls \$LS_OPTIONS'/" /root/.bashrc
sed -i "s/# alias ll='ls \$LS_OPTIONS -l'/alias ll='ls \$LS_OPTIONS -l'/" /root/.bashrc
sed -i "s/# alias l='ls \$LS_OPTIONS -lA'/alias l='ls \$LS_OPTIONS -lha'/" /root/.bashrc
echo '# Para usar o fzf use: CTRL+R' >> ~/.bashrc
echo 'source /usr/share/doc/fzf/examples/key-bindings.bash' >> ~/.bashrc
echo "alias grep='grep --color'" >> /root/.bashrc
echo "alias egrep='egrep --color'" >> /root/.bashrc
echo "alias ip='ip -c'" >> /root/.bashrc
echo "alias diff='diff --color'" >> /root/.bashrc
echo "alias tail='grc tail'" >> /root/.bashrc
echo "alias ping='grc ping'" >> /root/.bashrc
echo "alias ps='grc ps'" >> /root/.bashrc
echo "PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;31m\]\u\[\033[01;34m\]@\[\033[01;33m\]\h\[\033[01;34m\][\[\033[00m\]\[\033[01;37m\]\w\[\033[01;34m\]]\[\033[01;31m\]\\$\[\033[00m\] '" >> /root/.bashrc
echo "echo;echo 'SXZhbiBKciAtIENvbnN1bHRvcmlhIGVtIFRJQy4NCg0KV2Vic2l0ZSAuLi4uLi4uLi4uLjogaXZhbmpyLmV0aS5icg0KQ29udGF0byAuLi4uLi4uLi4uLi46IGNvbnRhdG9AaXZhbmpyLmV0aS5icg=='|base64 --decode; echo;" >> /root/.bashrc
=========
cat << EOF > /etc/issue
- Hostname do sistema ............: \n
- Data do sistema ................: \d
- Hora do sistema ................: \t
- IPv4 address ...................: \4
- Acess Web ......................: http://\4/moodle
- Contato ........................: contato@ivanjr.eti.br
- Ivan Jr - Consultoria em TIC.

EOF
clear
    IPVAR=`ip addr show | grep global | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' | sed -n '1p'
`
    echo http://$IPVAR/moodle
else
cat << EOF > /etc/issue
- Hostname do sistema ............: \n
- Data do sistema ................: \d
- Hora do sistema ................: \t
- IPv4 address ...................: \4
- Acess Web ......................: http://\4/moodle
- Contato ........................: contato@ivanjr.eti.br
- Ivan Jr - Consultoria em TIC.

EOF
clear
    echo "Instalação finalizada!"
    sleep 3
    IPVAR=`ip addr show | grep global | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' | sed -n '1p'
`
    echo http://$IPVAR/moodle
fi
