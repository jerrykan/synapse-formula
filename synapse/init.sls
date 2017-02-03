{%- from "synapse/map.jinja" import synapse with context -%}

synapse-service:
  service.running:
    - name: synapse
    - enable: True

synapse-restart:
  module.wait:
    - name: service.restart
    - m_name: synapse
    - require:
      - service: synapse-service
