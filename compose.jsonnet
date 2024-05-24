function(num_hosts=2)
  local common = {
    environment: {
      ax25_num_hosts: '%d' % num_hosts,
    },
    build: {
      context: '.',
    },
    init: true,
    cap_add: [
      'NET_ADMIN',
    ],
    devices: [
      '/dev/net/tun',
      '/dev/kvm',
    ],
    volumes: [
      './scripts:/scripts',
      './boot:/boot',
      './tests:/tests',
      'results:/results',
      'state:/state',
    ],
    restart: 'always',
  };

  local host(index) = common {
    network_mode: 'service:infra',
    environment+: {
      ax25_host_index: '%d' % index,
      ax25_kernel: '$AX25_KERNEL',
      ax25_initrd: '$AX25_INITRD',
    },
    depends_on: {
      infra: {
        condition: 'service_healthy',
      },
    },
    command: [
      'bash',
      '/scripts/run-host.sh',
      '%d' % (1000 + index),
      'host%d' % (index),
      '192.168.168.%d' % (10 + index),
    ],
  };

  {
    volumes: {
      results: {},
      state: {},
    },
    services: {
      infra: common {
        command: [
          'bash',
          '/scripts/setup-infra.sh',
        ],
        healthcheck: {
          interval: '5s',
          test: [
            'CMD',
            'curl',
            '-Ssf',
            'http://localhost:8080/health',
          ],
        },
      },
    } {
      ['host%d' % (index)]: host(index)
      for index in std.range(0, (num_hosts - 1))
    },
  }
