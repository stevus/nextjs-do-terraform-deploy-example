terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "default" {
  name       = "deployer-key"
  public_key = file(var.ssh_pub_key_path)
}

resource "digitalocean_droplet" "your_apps" {
  name   = "your-droplet"
  image  = "ubuntu-22-04-x64"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = self.ipv4_address
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io nginx certbot python3-certbot-nginx
              systemctl enable docker
              systemctl start docker
              systemctl enable nginx
              systemctl start nginx
              EOF
}

resource "digitalocean_domain" "yourdomainhere" {
  name = "yourdomainhere.com"
}

resource "digitalocean_record" "forcepushed_root" {
  domain = digitalocean_domain.forcepushed.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.your_apps.ipv4_address
  ttl    = 60
}

resource "digitalocean_record" "forcepushed_www" {
  domain = digitalocean_domain.forcepushed.name
  type   = "A"
  name   = "www"
  value  = digitalocean_droplet.your_apps.ipv4_address
  ttl    = 60
}

output "droplet_ip" {
  value = digitalocean_droplet.your_apps.ipv4_address
}
