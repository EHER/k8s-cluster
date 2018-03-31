variable "do_token" {}
variable "k8s_hostname" { default = "k8s.mydomain.com" }
variable "admin_ip" { default = "192.168.1.0/24" }

provider "digitalocean" { token = "${var.do_token}" }

resource "digitalocean_tag" "kubernetes" { name = "kubernetes" }
resource "digitalocean_tag" "master" { name = "master" }
resource "digitalocean_tag" "worker" { name = "worker" }

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
  tags = ["${digitalocean_tag.kubernetes.id}","${digitalocean_tag.master.id}"]
}

resource "digitalocean_floating_ip" "k8s_master_ip" {
  droplet_id = "${digitalocean_droplet.k8s_master.id}"
  region = "${digitalocean_droplet.k8s_master.region}"
}

resource "digitalocean_domain" "default" {
  name = "${var.k8s_hostname}"
  ip_address = "${digitalocean_floating_ip.k8s_master_ip.ip_address}"
}

resource "digitalocean_firewall" "kubernetes" {
  name = "Kubernetes"
  tags = ["${digitalocean_tag.kubernetes.id}"]
  inbound_rule = [
    { protocol = "tcp" port_range = "22" source_addresses = ["${var.admin_ip}"] },
    { protocol = "tcp" port_range = "80" source_addresses = ["0.0.0.0/0", "::/0"] },
    { protocol = "tcp" port_range = "443" source_addresses = ["0.0.0.0/0", "::/0"] },
  ]

}
