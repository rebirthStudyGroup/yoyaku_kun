# Copyright 2013 Thatcher Peskens
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#FROM ubuntu:18.04
FROM ubuntu:19.10
#FROM ubuntu:20.04

MAINTAINER Dockerfiles

# Install required packages and remove the apt packages cache when done.

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
	git \
	python3.7 \
	python3.7-dev \
	python3-setuptools \
	python3-pip \
	python3-bcrypt \
	nginx \
	libmysqlclient-dev \
	supervisor \
	sqlite3 && \
	pip3 install -U pip setuptools && \
   rm -rf /var/lib/apt/lists/*

RUN pip3 install uwsgi
RUN pip3 install python-dateutil --upgrade
RUN pip3 install mysqlclient==1.4.4
RUN pip3 install pymysql
#RUN pip3 install python3-bcrypt --user

# setup all the configfiles
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY nginx-app.conf /etc/nginx/sites-available/default
COPY supervisor-app.conf /etc/supervisor/conf.d/

# COPY requirements.txt and RUN pip install BEFORE adding the rest of your code, this will cause Docker's caching mechanism
# to prevent re-installing (all your) dependencies when you made a change a line or two in your app.

#COPY requirements.txt /home/docker/code/
COPY internal_rsv_system/requirements.txt /home/docker/code/
RUN pip3 install -r /home/docker/code/requirements.txt

# add (the rest of) our code
#COPY . /home/docker/code/
#COPY internal_rsv_system /home/docker/code/
COPY . /home/docker/code/

# install django, normally you would remove this step because your project would already
# be installed in the code/app/ directory
#RUN django-admin.py startproject website /home/docker/code/app/

EXPOSE 80
CMD ["supervisord", "-n"]
