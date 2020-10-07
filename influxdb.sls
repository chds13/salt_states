---
{% set statename = "influxdb.sls" %}
{% if grains['os'] == "CentOS" %}
add_influx_repo:
  pkgrepo.managed:
    - name: influxdata
    - enabled: True
    - humanname:  InfluxDB Repository - RHEL $releasever
    - baseurl: https://repos.influxdata.com/rhel/$releasever/$basearch/stable
    - gpgcheck: 1
    - gpgkey: https://repos.influxdata.com/influxdb.key

influxdb:
  pkg.installed:
    - require:
      - pkgrepo: add_influx_repo

influxdb.service:
  service.running:
    - name: influxdb.service
    - enable: True

{% endif %}