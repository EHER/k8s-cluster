variable "do_token" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_ssh_key" "default" {
  name = "Terraform Key"
  public_key = "${file("./secret/id_rsa.pub")}"
}

resource "digitalocean_droplet" "k8s_master" {
  image = "coreos-stable"
  name = "k8s-master"
  private_networking = true
  region = "ams3"
  size = "s-1vcpu-1gb"
  ssh_keys = ["${digitalocean_ssh_key.default.fingerprint}"]
}

resource "digitalocean_floating_ip" "k8s_master_ip" {
  droplet_id = "${digitalocean_droplet.k8s_master.id}"
  region = "${digitalocean_droplet.k8s_master.region}"
}

resource "digitalocean_domain" "default" {
  name       = "k8s.eher.com.br"
  ip_address = "${digitalocean_floating_ip.k8s_master_ip.ip_address}"
}
