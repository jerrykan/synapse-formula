base:
  'test_*':
    - {{ grains.id }}

  # used when developing the formula
  'not test_*':
    - default
