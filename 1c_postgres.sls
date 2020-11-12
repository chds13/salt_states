---
{% if grains['os'] == "Ubuntu" %}
us_locale:
  locale.present:
    - name: en_US.UTF-8

ru_locale:
  locale.present:
    - name: ru_RU.UTF-8

default_locale:
  locale.system:
    - name: ru_RU.UTF-8
    - require:
      - locale: us_locale
      - locale: ru_locale
pgrepo:
  pkgrepo.managed:
    - name: deb [arch=amd64] http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main
    - file: /etc/apt/sources.list.d/postgres.list
    - gpgcheck: 1
    - key_url: https://www.postgresql.org/media/keys/ACCC4CF8.asc
    - require_in:
      - pkg: postgresql-common

postgresql-common:
  pkg.installed

libicu55:
  pkg.installed:
    - sources:
      - libicu55: http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu55_55.1-7_amd64.deb

postgresql:
  pkg.installed:
    - sources:
      - libpq5: http://192.168.123.253/1c/pg_11.9/linux_deb/amd64/libpq5_11.9-1.1C_amd64.deb
      - postgresql-client-11: http://192.168.123.253/1c/pg_11.9/linux_deb/amd64/postgresql-client-11_11.9-1.1C_amd64.deb
      - postgresql-11: http://192.168.123.253/1c/pg_11.9/linux_deb/amd64/postgresql-11_11.9-1.1C_amd64.deb
    - hold: True
{% endif %}
