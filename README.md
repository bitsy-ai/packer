# Bitsy AI Labs Packer

Cross-arch Raspberry Pi image builder. Create ARM images from an x86 host using:

* https://github.com/multiarch/qemu-user-static
* https://github.com/mkaczanowski/packer-builder-arm


## Bake image from existing templates

```
$ make dist/printnanny-pi-buster.img
$ make dist/printnanny-pi-buster.img
```

## Create a new template

1. Create a new Packer template

```
$ touch templates/<image name>-<variant>.pkr.hcl
```

For examples of an image created using an Ansible provisioner, see `templates/printnanny-pi-bullseye.pkr.hcl`.

Please refer to [Packer's documentation](https://www.packer.io/docs/provisioners) for provisioners / builders usage.

2. Provide variables

Parameterize a Packer template with a `-var-file vars/<image name>-<variant>.pkrvars.hcl` and/or in-line values `-var `.

3. Ansible Provisioner

If using Packer's Ansible provisioner, specify collection/role dependencies in `playbooks/requirements.yml` 