{%- from "synapse/map.jinja" import synapse with context -%}

{%- set app_services = salt['pillar.get']('synapse:app_services', {}) -%}

include:
  - synapse
  - synapse.install
  - synapse.user

synapse-conf-dir:
  file.directory:
    - name: {{ synapse.conf_dir }}

synapse-app-services-dir:
  file.directory:
    - name: {{ synapse.app_services_dir }}

synapse-conf-file:
  file.managed:
    - name: {{ synapse.conf_file }}
    - source: salt://synapse/files/homeserver.yaml.jinja
    - template: jinja
    - require:
      - file: synapse-conf-dir
    - require_in:
      - service: synapse-service
    - watch_in:
      - module: synapse-restart

{% for id, config in app_services|dictsort %}
synapse-app-service-{{ id }}-file:
  file.managed:
    - name: {{ synapse.app_services_dir }}/{{ id }}.yaml
    - source: salt://synapse/files/app_service.yaml.jinja
    - template: jinja
    - context:
        id: {{ id }}
        config: {{ config }}
    - require:
      - file: synapse-app-services-dir
    - watch_in:
      - module: synapse-restart
{%- endfor %}

synapse-log-conf-file:
  file.managed:
    - name: {{ synapse.log_conf_file }}
    - source: salt://synapse/files/log_config.jinja
    - template: jinja
    - require:
      - file: synapse-conf-dir
    - require_in:
      - service: synapse-service
    - watch_in:
      - module: synapse-restart

synapse-tls-dir:
  file.directory:
    - name: {{ synapse.tls_dir }}
    - user: {{ synapse.user }}
    - group: {{ synapse.user }}
    - mode: 750
    - require:
      - user: synapse-user
      - file: synapse-conf-dir

synapse-tls-files:
  cmd.run:
    - name: {{ synapse.synapse_dir }}/bin/python -m synapse.app.homeserver --generate-keys -c {{ synapse.conf_file }}
    - unless: test -f {{ synapse.tls_cert_file }} -a -f {{ synapse.tls_key_file }} -a -f {{ synapse.signing_key_file }}
    - require:
      - file: synapse-conf-file
      - file: synapse-tls-dir
      - virtualenv: synapse-virtualenv
    - watch_in:
      - module: synapse-restart
