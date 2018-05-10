variable "do_token" {}
variable "k8s_domain" {}

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
  tags = ["${digitalocean_tag.master.id}","${digitalocean_tag.kubernetes.id}"]
  connection {
    type = "ssh"
    user = "core"
    private_key = "${file("./secret/id_rsa")}"
  }
  provisioner "file" {
    source      = "k8s_master.sh"
    destination = "/tmp/provision.sh"
  }
  provisioner "file" {
    source      = "kubectl.sh"
    destination = "/tmp/kubectl.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "chmod +x /tmp/kubectl.sh",
      "sudo /tmp/provision.sh",
      "/tmp/kubectl.sh",
    ]
  }
}

resource "digitalocean_droplet" "k8s_worker_1" {
  image = "coreos-stable"
  name = "k8s-worker-1"
  private_networking = true
  region = "ams3"
  size = "s-1vcpu-1gb"
  ssh_keys = ["${digitalocean_ssh_key.default.fingerprint}"]
  tags = ["${digitalocean_tag.worker.id}","${digitalocean_tag.kubernetes.id}"]
  connection {
    type = "ssh"
    user = "core"
    private_key = "${file("./secret/id_rsa")}"
  }
  provisioner "file" {
    source      = "k8s_worker.sh"
    destination = "/tmp/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh",
    ]
  }
}

resource "digitalocean_droplet" "k8s_worker_2" {
  image = "coreos-stable"
  name = "k8s-worker-2"
  private_networking = true
  region = "ams3"
  size = "s-1vcpu-1gb"
  ssh_keys = ["${digitalocean_ssh_key.default.fingerprint}"]
  tags = ["${digitalocean_tag.worker.id}","${digitalocean_tag.kubernetes.id}"]
  connection {
    type = "ssh"
    user = "core"
    private_key = "${file("./secret/id_rsa")}"
  }
  provisioner "file" {
    source      = "k8s_worker.sh"
    destination = "/tmp/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh",
    ]
  }
}

resource "digitalocean_floating_ip" "k8s_master_ip" {
  droplet_id = "${digitalocean_droplet.k8s_master.id}"
  region = "${digitalocean_droplet.k8s_master.region}"
}

resource "digitalocean_domain" "master" {
  name = "master.${var.k8s_domain}"
  ip_address = "${digitalocean_floating_ip.k8s_master_ip.ip_address}"
}

resource "digitalocean_loadbalancer" "k8s_loadbalancer" {
  name = "k8s-loadbalancer"
  region = "${digitalocean_droplet.k8s_master.region}"
  droplet_tag = "${digitalocean_tag.kubernetes.id}"
  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"
    target_port = 80
    target_protocol = "http"
  }
  forwarding_rule {
    entry_port = 22
    entry_protocol = "tcp"
    target_port = 22
    target_protocol = "tcp"
  }
  healthcheck {
    port = 22
    protocol = "tcp"
  }
}

resource "digitalocean_domain" "k8s" {
  name = "k8s.${var.k8s_domain}"
  ip_address = "${digitalocean_loadbalancer.k8s_loadbalancer.ip}"
}
