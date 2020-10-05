---
{% set statename = "node_exporter.sls" %}
{% if grains['os'] == "Ubuntu" %}
pkgs:
  pkg.installed:
    - pkgs: [ wget, tar ]

add_user_node_exporter:
  user.present:
    - name: node_exporter
    - usergroup: True
    - shell: /bin/false
    - home: /
    - createhome: False
    - system: True

{% if not salt['service.available']('node_exporter.service') %}
download:
  cmd.run:
    - name: cd /tmp &&
            wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz &&
            tar xf /tmp/node_exporter-*.linux-amd64.tar.gz
    - require:
      - pkg: pkgs

install:
  cmd.run:
    - name: cd /tmp/node_exporter-*.linux-amd64 &&
            cp node_exporter /usr/local/bin
    - require:
      - cmd: download
{% endif %}

{% set unit = "/etc/systemd/system/node_exporter.service" %}
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
    - backup: ".bak"
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
        Description=Node Exporter Daemon
        After=network.target
        
        [Service]
        User=node_exporter
        Group=node_exporter
        Type=simple
        ExecStart=/usr/local/bin/node_exporter
        ExecReload=/bin/kill -HUP $MAINPID
        Restart=on-failure
        
        ProtectSystem=strict
        ProtectControlGroups=true
        ProtectKernelModules=true
        ProtectKernelTunables=true
        
        PrivateTmp=yes
        ProtectHome=yes
        NoNewPrivileges=yes
        
        PrivateDevices=yes
        ProtectKernelTunables=yes
        ProtectControlGroups=yes
        
        [Install]
        WantedBy=multi-user.target
    - require_in:
      - file: set_{{ unit }}

daemon_node_exporter.service:
  service.running:
    - name: node_exporter.service
    - enable: True
    - watch:
      - file: set_{{ unit }}

{% endif %}
