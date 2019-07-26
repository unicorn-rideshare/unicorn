FROM ubuntu:latest

RUN /bin/bash -l -c 'useradd provide -s /bin/bash && mkdir -p /home/provide && chown -R provide:provide /home/provide'

RUN /bin/bash -l -c 'apt-get update -qq && apt-get upgrade -y && apt-get install -y curl wget git gnupg2 nginx nodejs npm ruby g++ qt5-default libqt5webkit5-dev libxml2-dev libxslt1-dev openssl qt5-qmake libpq-dev sudo unattended-upgrades'
RUN /bin/bash -l -c 'echo -e "APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Unattended-Upgrade \"1\";\n" > /etc/apt/apt.conf.d/20auto-upgrades'

RUN /bin/bash -l -c 'npm install -g n && n stable && npm install bower -g'

RUN /bin/bash -l -c 'mkdir -p /mnt/tmp'
RUN /bin/bash -l -c 'mkdir -p /etc/pki'

RUN /bin/bash -l -c 'openssl genrsa -passout pass:x -out server.pass.key 4096'
RUN /bin/bash -l -c 'openssl rsa -passin pass:x -in server.pass.key -out /etc/pki/server.key'
RUN /bin/bash -l -c 'rm server.pass.key'
RUN /bin/bash -l -c 'openssl req -new -key /etc/pki/server.key -out /etc/pki/server.csr -subj "/C=US/ST=Georgia/L=Atlanta"'
RUN /bin/bash -l -c 'openssl x509 -req -in /etc/pki/server.csr -signkey /etc/pki/server.key -out /etc/pki/server.crt'
RUN /bin/bash -l -c 'chmod 0600 /etc/pki/server.key && chmod 0600 /etc/pki/server.crt'

RUN /bin/bash -l -c 'mkdir ~/.gnupg && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf'
RUN /bin/bash -l -c 'gpg2 --homedir ~/.gnupg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && gpg --armor --export $KEY | apt-key add -'
RUN /bin/bash -l -c 'curl -sSL https://rvm.io/mpapis.asc | gpg --import - && curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -'
RUN /bin/bash -l -c 'curl -sSL https://get.rvm.io | bash -s stable --ruby=ruby-2.3.1'
RUN /bin/bash -l -c 'adduser provide rvm'

RUN /bin/bash -l -c 'apt-get install -y openssh-client'

ADD nginx-site /etc/nginx/sites-available/default
RUN /bin/bash -l -c 'echo "provide ALL=(ALL) NOPASSWD: /usr/sbin/service nginx start,/usr/sbin/service nginx stop,/usr/sbin/service nginx restart" > /etc/sudoers'

COPY . /opt/provide
RUN /bin/bash -l -c 'chown -R provide:provide /opt/provide'

USER provide
WORKDIR /opt/provide

RUN /bin/bash -l -c 'gem install bundler'
RUN /bin/bash -l -c 'source /etc/profile.d/rvm.sh && bundle install'

RUN /bin/bash -l -c 'mkdir -p tmp'

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/opt/provide/lib/containers/start-rails.sh"]
