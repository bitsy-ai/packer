base_image_stamp = "2021-11-16-0605-generic-pi-bullseye-arm64"
base_image_url = "https://cdn.print-nanny.com/releases/generic-pi-bullseye-arm64/2021-11-20-0727-generic-pi-bullseye-arm64/2021-11-20-0727-generic-pi-bullseye-arm64.tar.gz"
base_image_checksum = "https://cdn.print-nanny.com/releases/generic-pi-bullseye-arm64/2021-11-20-0727-generic-pi-bullseye-arm64/sha256.checksum"
playbook_file = "./playbooks/printnanny.yml"
ansible_extra_vars = "vars/generic-pi-arm64.ansiblevars.yml"
base_image_ext = ".tar.gz"
image_name = "printnanny-os-bullseye-arm64"