---
{% set statename = "telegraf.sls" %}
{% if grains['os'] == "CentOS" %}
add_influx_repo:
  pkgrepo.managed:
    - name: influxdata
    - enabled: True
    - humanname: InfluxDB Repository - RHEL $releasever
    - baseurl: https://repos.influxdata.com/rhel/$releasever/$basearch/stable
    - gpgcheck: 1
    - gpgkey: https://repos.influxdata.com/influxdb.key

telegraf:
  pkg.installed:
    - require:
      - pkgrepo: add_influx_repo

{% endif %}