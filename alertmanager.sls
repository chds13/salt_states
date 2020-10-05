---
{% set statename = "alertmanager.sls" %}
{% if grains['os'] == "Ubuntu" %}
pkgs:
  pkg.installed:
    - pkgs: [ wget, tar ]

add_user_alertmanager:
  user.present:
    - name: alertmanager
    - usergroup: True
    - shell: /bin/false
    - home: /
    - createhome: False
    - system: True

/etc/alertmanager:
  file.directory:
    - name: /etc/alertmanager
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode

/var/lib/alertmanager:
  file.directory:
    - name: /var/lib/alertmanager
    - user: alertmanager
    - group: alertmanager
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: add_user_alertmanager

{% if not salt['service.available']('alertmanager.service') %}
download:
  cmd.run:
    - name: cd /tmp &&
           wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz &&
           tar xf /tmp/alertmanager-*.linux-amd64.tar.gz

install:
  cmd.run:
    - name: cd /tmp/alertmanager-*.linux-amd64 &&
            cp alertmanager amtool /usr/local/bin/ &&
            cp alertmanager.yml /etc/alertmanager/
    - require:
      - cmd: download
{% endif %}

{% set unit = "/etc/systemd/system/alertmanager.service" %}
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
        Description=Alertmanager daemon for prometheus
        After=network.target
        
        [Service]
        User=alertmanager
        Group=alertmanager
        Type=simple
        ExecStart=/usr/local/bin/alertmanager \
        --config.file=/etc/alertmanager/alertmanager.yml \
        --storage.path=/var/lib/alertmanager \
        $ALERTMANAGER_OPTS
        ExecReload=/bin/kill -HUP $MAINPID
        Restart=on-failure
        
        [Install]
        WantedBy=multi-user.target
    - require_in:
      - file: set_{{ unit }}

alertmanager.service:
  service.running:
    - name: alertmanager.service
    - enable: True
    - watch:
      - file: set_{{ unit }}

{% endif %} 