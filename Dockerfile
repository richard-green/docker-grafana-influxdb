FROM ubuntu:18.04

ENV GRAFANA_VERSION 6.7.3
ENV INFLUXDB_VERSION 1.8.0

# Prevent some error messages
ENV DEBIAN_FRONTEND noninteractive

#RUN echo 'deb http://us.archive.ubuntu.com/ubuntu/ Utopic Unicorn' >> /etc/apt/sources.list
RUN apt-get -y update && apt-get -y upgrade

# ------------ #
# Installation #
# ------------ #

# Install all prerequisites
RUN apt-get -y install wget nginx-light supervisor curl

# Install Grafana to /src/grafana
RUN mkdir -p src/grafana && cd src/grafana && \
    wget -nv https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz -O grafana.tar.gz && \
    tar xzf grafana.tar.gz --strip-components=1 && rm grafana.tar.gz

# Install InfluxDB
RUN wget -nv https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# ------------- #
# Configuration #
# ------------- #

# Configure InfluxDB
ADD influxdb/config.toml /etc/influxdb/config.toml
ADD influxdb/run.sh /usr/local/bin/run_influxdb

# These two databases have to be created. These variables are used by set_influxdb.sh and set_grafana.sh
ENV PRE_CREATE_DB data grafana
ENV INFLUXDB_HOST localhost:8086
ENV INFLUXDB_DATA_USER data
ENV INFLUXDB_DATA_PW data
ENV INFLUXDB_GRAFANA_USER grafana
ENV INFLUXDB_GRAFANA_PW grafana
ENV ROOT_PW root

# Configure Grafana
ADD ./grafana/config.ini /etc/grafana/config.ini
ADD grafana/run.sh /usr/local/bin/run_grafana
ADD ./configure.sh /configure.sh
ADD ./set_grafana.sh /set_grafana.sh
ADD ./set_influxdb.sh /set_influxdb.sh

# Sed to convert windows line endings
RUN sed 's/\r$//' /etc/grafana/config.ini > /etc/grafana/config.ini
RUN sed 's/\r$//' /usr/local/bin/run_grafana > /usr/local/bin/run_grafana
RUN sed 's/\r$//' /configure.sh > /configure.sh
RUN sed 's/\r$//' /set_grafana.sh > /set_grafana.sh
RUN sed 's/\r$//' /set_influxdb.sh > /set_influxdb.sh

# Run setup
RUN /configure.sh

# Configure nginx and supervisord
ADD ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Sed to convert windows line endings
RUN sed 's/\r$//' /etc/nginx/nginx.conf > /etc/nginx/nginx.conf
RUN sed 's/\r$//' /etc/supervisor/conf.d/supervisord.conf > /etc/supervisor/conf.d/supervisord.conf

# ------- #
# Cleanup #
# ------- #

RUN apt-get autoremove -y wget curl && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && rm /*.sh

# ------------ #
# Expose Ports #
# ------------ #

# Grafana
EXPOSE 3000

# InfluxDB Admin server
EXPOSE 8083

# InfluxDB HTTP API
EXPOSE 8086

# InfluxDB HTTPS API
EXPOSE 8084

# ---- #
# Run! #
# ---- #

#CMD ["/usr/bin/supervisord"]
