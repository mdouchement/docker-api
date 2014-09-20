module Docker
  module Testing
    module Container
      module Template
        # This template is based on Docker 1.1.0 (1.13)
        def new_template
          {
            'Args' => [],
            'Config' => {
              'AttachStderr' => false,
              'AttachStdin' => false,
              'AttachStdout' => false,
              'Cmd' => ['/bin/bash'],
              'CpuShares' => 0,
              'Cpuset' => '',
              'Domainname' => '',
              'Entrypoint' => nil,
              'Env' => ['HOME=/', 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'],
              'ExposedPorts' => nil,
              'Hostname' => SecureRandom.hex(6),
              'Image' => '',
              'Memory' => 0,
              'MemorySwap' => 0,
              'NetworkDisabled' => false,
              'OnBuild' => nil,
              'OpenStdin' => false,
              'PortSpecs' => nil,
              'StdinOnce' => false,
              'Tty' => false,
              'User' => '',
              'Volumes' => nil,
              'WorkingDir' => ''
            },
            'Created' => '0001-01-01T00:00:00Z',
            'Driver' => 'devicemapper',
            'ExecDriver' => 'native-0.2',
            'HostConfig' => {
              'Binds' => nil,
              'ContainerIDFile' => '',
              'Dns' => nil,
              'DnsSearch' => nil,
              'Links' => nil,
              'LxcConf' => nil,
              'NetworkMode' => '',
              'PortBindings' => nil,
              'Privileged' => false,
              'PublishAllPorts' => false,
              'VolumesFrom' => nil
            },
            'HostnamePath' => '',
            'HostsPath' => '',
            'Image' => 'ba5877dc9beca5a0af9521846e79419e98575a11cbfe1ff2ad2e95302cff26bf',
            'MountLabel'  => '',
            'Name' => '',
            'NetworkSettings' => {
              'Bridge' => 'docker0',
              'Gateway' => '172.17.42.1',
              'IPAddress' => '172.17.0.21',
              'IPPrefixLen' => 16,
              'PortMapping' => nil,
              'Ports' => nil
            },
            'Path' => '/bin/bash',
            'ProcessLabel' => '',
            'ResolvConfPath' => '',
            'State' => {
              'ExitCode' => 0,
              'FinishedAt' => '0001-01-01T00:00:00Z',
              'Paused' => false,
              'Pid' => 0,
              'Running' => false,
              'StartedAt' => '0001-01-01T00:00:00Z'
            },
            'Volumes' => nil,
            'VolumesRW' => nil,
            'id' => ''
          }
        end
      end
    end
  end
end
