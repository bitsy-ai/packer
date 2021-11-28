base_image_stamp = "2021-10-30-raspios-bullseye-arm64"
base_image_url = "file:./build/raspios-bullseye-slim-arm64.img"
base_image_checksum = "file:/build/sha256.checksum"
base_image_ext = ".img"
playbook_file = "./playbooks/slim.yml"
ansible_extra_vars = "vars/generic-pi-arm64.ansiblevars.yml"
image_name = "raspios-bullseye-slim-arm64"
image_size = "3.2G"