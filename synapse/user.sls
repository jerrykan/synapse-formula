{%- from "synapse/map.jinja" import synapse with context -%}

synapse-user:
  user.present:
    - name: {{ synapse.user }}
    - home: {{ synapse.data_dir }}
    - createhome: False
    - shell: /usr/sbin/nologin
    - system: True
