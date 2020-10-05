---
{% set statename = "grafana" %}
{% if grains['os'] == "Ubuntu" %}

pkg_grafana:
  pkgrepo.managed:
    - name: deb https://packages.grafana.com/enterprise/deb stable main
    - enabled: True
    - architectures: amd64
    - file: /etc/apt/sources.list.d/grafana.list
    - key_url: https://packages.grafana.com/gpg.key
    - require_in:
      - pkg: grafana
  pkg.installed:
    - name: grafana

running_daemon_grafana:
  service.running:
    - name: grafana-server
    - enable: True
    - watch:
      - pkg: grafana

{% endif %}