#cloud-config
autoinstall:
  version: 1
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
      - arches: [amd64, i386]
        uri: http://us.archive.ubuntu.com/ubuntu
      - arches: [default]
        uri: http://ports.ubuntu.com/ubuntu-ports  
  early-commands:
    # Ensures that Packer does not connect too soon.
    - sudo systemctl stop ssh
  locale: ${vm_guest_os_language}
  keyboard:
    layout: ${vm_guest_os_keyboard}
  storage:
    layout:
      name: lvm
  identity:
    hostname: ubuntu-server
    username: ${build_username}
    password: ${build_password_encrypted}
  network:
    network:
      version: 2
      ethernets:
        ens192: 
          dhcp4: true
          dhcp-identifier: mac
  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
      - ${build_key}
  packages:
    - openssh-server
    - open-vm-tools
    - net-tools
    - cloud-init #Version that ships with Ubuntu doesn't have the VMware datasource OOB
  user-data:
    disable_root: false
    package_update: true
    package_upgrade: true
    package_reboot_if_required: true
    timezone: ${vm_guest_os_timezone}
  late-commands:
    - echo '${build_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}
    - sed -i "s/.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
    - curtin in-target --target=/target -- apt-get update
    - curtin in-target --target=/target -- apt-get upgrade --yes