{%- from "synapse/map.jinja" import synapse with context -%}

{%- set postgres_db = salt['pillar.get']('synapse:config:database_engine') == 'psycopg2' -%}
{%- set pip_index_url = synapse.get('venv_env_vars', {}).get('PIP_INDEX_URL') -%}

include:
  - synapse
  - synapse.user

synapse-dependencies:
  pkg.installed:
    - pkgs:
{%- for pkg in synapse.pkg_dependencies %}
      - {{ pkg }}
{%- endfor %}
{%- if postgres_db %}
      - {{ synapse.pkg_postgres }}
{%- else %}
      - {{ synapse.pkg_sqlite3 }}
{%- endif %}

synapse-dir:
  file.directory:
    - name: {{ synapse.synapse_dir }}
    - user: {{ synapse.user }}
    - group: {{ synapse.user }}

{% if pip_index_url -%}
# Slight hack to make easy_install correctly use an index_url if one is being
# used with pip
synapse-pydistutils_cfg-file:
  file.managed:
    - name: {{ synapse.data_dir }}/.pydistutils.cfg
    - contents: |
        [easy_install]
        index_url = {{ pip_index_url }}
    - require:
      - user: synapse-user
    - require_in:
      - virtualenv: synapse-virtualenv-pre
{%- endif %}

# The setuptools package in the virtualenv needs to be upgraded before we can
# install synapse and upgrading pip avoids warnings being displayed
synapse-virtualenv-pre:
  virtualenv.managed:
    - name: {{ synapse.synapse_dir }}
    - user: {{ synapse.user }}
    - pip_upgrade: True
    - pip_pkgs:
      - pip
      - setuptools
{%- if synapse.get('venv_env_vars', {}) %}
    - env_vars:
{%- for name, value in synapse.venv_env_vars|dictsort %}
        {{ name }}: {{ value }}
{%- endfor %}
{%- endif %}
    - require:
      - user: synapse-user
      - file: synapse-dir
      - pkg: synapse-dependencies

synapse-virtualenv:
  virtualenv.managed:
    - name: {{ synapse.synapse_dir }}
    - user: {{ synapse.user }}
    - pip_pkgs:
      - {{ synapse.synapse_archive }}
{%- if postgres_db %}
      - psycopg2
{%- endif %}
{%- if synapse.get('venv_env_vars', {}) %}
    - env_vars:
{%- for name, value in synapse.venv_env_vars|dictsort %}
        {{ name }}: {{ value }}
{%- endfor %}
{%- endif %}
    - require:
      - virtualenv: synapse-virtualenv-pre
      - user: synapse-user
    - require_in:
      - service: synapse-service
    - watch_in:
      - module: synapse-restart

synapse-systemd-file:
  file.managed:
    - name: /etc/systemd/system/synapse.service
    - source: salt://synapse/files/synapse.service.jinja
    - template: jinja
    - require_in:
      - service: synapse-service

synapse-log-dir:
  file.directory:
    - name: {{ synapse.log_dir }}
    - user: {{ synapse.user }}
    - group: {{ synapse.user }}
    - require:
      - user: synapse-user
    - require_in:
      - service: synapse-service

synapse-data-dir:
  file.directory:
    - name: {{ synapse.data_dir }}
    - user: {{ synapse.user }}
    - group: {{ synapse.user }}
    - require:
      - user: synapse-user

synapse-media-store-dir:
  file.directory:
    - name: {{ synapse.media_store_dir }}
    - user: {{ synapse.user }}
    - group: {{ synapse.user }}
    - require:
      - user: synapse-user
      - file: synapse-data-dir
    - require_in:
      - service: synapse-service

synapse-uploads-dir:
  file.directory:
    - name: {{ synapse.uploads_dir }}
    - user: {{ synapse.user }}
    - group: {{ synapse.user }}
    - require:
      - user: synapse-user
      - file: synapse-data-dir
    - require_in:
      - service: synapse-service
