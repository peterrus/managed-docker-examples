FROM python:3.7-stretch

EXPOSE 80 2222

# ssh
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
        && apt-get install -y --no-install-recommends dialog \
        && apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd 

COPY sshd_config /etc/ssh/
COPY init.sh /usr/local/bin/

RUN chmod u+x /usr/local/bin/init.sh

# app code
WORKDIR /usr/src/app
# ssl cert for mysql connection
RUN curl -L https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem -o BaltimoreCyberTrustRoot.crt.pem
COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN pip install pylint

COPY . .
# TODO: implement gunicorn or some other productiongrade server

ENTRYPOINT ["init.sh"]