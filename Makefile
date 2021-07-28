


install-vagrant:
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
	sudo apt-get update && sudo apt-get install vagrant

install-packer-builder-arm-image:
	git clone https://github.com/solo-io/packer-builder-arm-image
	cd packer-builder-arm-image