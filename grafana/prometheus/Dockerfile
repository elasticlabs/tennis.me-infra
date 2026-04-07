FROM prom/prometheus:latest
COPY config/prometheus.yml /etc/prometheus/prometheus.yml
CMD ["--config.file=/etc/prometheus/prometheus.yml","--storage.tsdb.path=/prometheus","--web.enable-lifecycle"]
