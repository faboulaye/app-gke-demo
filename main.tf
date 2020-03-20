provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

data "template_file" "hello" {
  template = file("index.tpl")
  vars = {
    hostname = "apache-server-${random_id.server_id.hex}"
  }
}


resource "random_id" "server_id" {
  byte_length = 4
}

resource "google_compute_instance" "appserver" {
  name         = "apache-server-${random_id.server_id.hex}"
  description  = "Apache web server"
  zone         = var.zone
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata_startup_script = "sudo apt-get update && sudo apt-get install apache2 -y && echo '${data.template_file.hello.rendered}' | sudo tee /var/www/html/index.html"

  network_interface {
    network = google_compute_network.app-network.name
    access_config {
      // Include this section to give the VM an external ip address
    }
  }
  tags = ["http-server", "webapp", "apache"]
}

resource "google_compute_firewall" "app-firewall" {
  name        = "webapp-firewall"
  description = "Firewall allow http exchange"
  network     = google_compute_network.app-network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_network" "app-network" {
  name = "webapp-network"
}


