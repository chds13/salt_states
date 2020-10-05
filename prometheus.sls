---
{% set statename = "prometheus.sls" %}
{% if grains['os'] == 'Ubuntu' %}
pkgs:
  pkg.installed:
    - pkgs: [ wget, tar ]

add_user_prometheus:
  user.present:
    - name: prometheus
    - usergroup: True
    - shell: /bin/false
    - home: /
    - createhome: False
    - system: True

/etc/prometheus:
  file.directory:
    - name: /etc/prometheus
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode

/var/lib/prometheus:
  file.directory:
    - name: /var/lib/prometheus
    - user: prometheus
    - group: prometheus
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: add_user_prometheus

{% if not salt['service.available']('prometheus.service') %}
download:
  cmd.run:
    - name: cd /tmp &&
            wget https://github.com/prometheus/prometheus/releases/download/v2.21.0/prometheus-2.21.0.linux-amd64.tar.gz &&
            tar xf /tmp/prometheus-*.linux-amd64.tar.gz

install:
  cmd.run:
    - name: cd /tmp/prometheus-*.linux-amd64 &&
            cp prometheus promtool /usr/local/bin &&
            cp prometheus.yml /etc/prometheus &&
    - require:
      - cmd: download
{% endif %}

{% set unit = "/etc/systemd/system/prometheus.service" %}
create_{{ unit }}:
  file.managed:
    - name: {{ unit }}
    - user: root
    - group: root
    - mode: 644
    - replace: False
    - create: True

set_{{ unit }}:
  file.blockreplace:
    - name: {{ unit }}
    - marker_start: "# --- START managed zone by {{ statename }} ---"
    - marker_end: "# --- END managed zone by {{ statename }} ---"
    - content: "# DO-NOT-MANUAL-EDIT"
    - append_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - require:
      - file: create_{{ unit }}
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: set_{{ unit }}

acc:
  file.accumulated:
    - filename: {{ unit }}
    - name: acc1
    - text: |
        [Unit]
        Description=Prometheus Daemon
        After=network.target
        
        [Service]
        User=prometheus
        Group=prometheus
        Type=simple
        ExecStart=/usr/local/bin/prometheus \
        --config.file /etc/prometheus/prometheus.yml \
        --storage.tsdb.path /var/lib/prometheus/ \
        --web.console.templates=/etc/prometheus/consoles \
        --web.console.libraries=/etc/prometheus/console_libraries
        ExecReload=/bin/kill -HUP $MAINPID
        Restart=on-failure
        
        [Install]
        WantedBy=multi-user.target
    - require_in:
      - file: set_{{ unit }}

prometheus.service:
  service.running:
    - name: prometheus.service
    - enable: True
    - watch:
      - file: set_{{ unit }}

{% endif %}

