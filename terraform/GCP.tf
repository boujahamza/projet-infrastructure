# Configure the GCP provider
provider "google" {
  project = "strong-pursuit-372520"
  credentials = "${file("credentials.json")}"
  region  = "europe-west9"
  zone = "europe-west9-a"
}

# Create random token
resource "random_string" "token_1" {
  length = 6
  upper = false
  special = false
}
resource "random_string" "token_2" {
  length = 16
  upper = false
  special = false
}

# Create a new GCE instance
resource "google_compute_instance" "k8s_master_node" {
  count = 1
  name         = "k8s-master-${count.index}"
  machine_type = "e2-small"
  zone         = "europe-west9-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }
  network_interface {
    network="default"
    access_config{
    }
    network_ip = "10.200.15.208"
  }

  metadata = {
  }
  
  metadata_startup_script = templatefile("${path.module}/master-startup-script.sh", {
    token_1 = "${random_string.token_1.result}"
    token_2 = "${random_string.token_2.result}"
  })
  
  
}



resource "google_compute_instance" "k8s_slave_node" {
  count = 2
  name         = "k8s-slave-${count.index}"
  machine_type = "e2-small"
  zone         = "europe-west9-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }
  network_interface {
    network="default"
    access_config{
      ###Empty
    }
  }
  # Install and configure Kubernetes
  metadata = {
    "install-kubernetes" = "true"
  }
  metadata_startup_script = templatefile("${path.module}/slave-startup-script.sh", {
    token_1 = "${random_string.token_1.result}"
    token_2 = "${random_string.token_2.result}"
    master_ip = "${google_compute_instance.k8s_master_node[0].network_interface[0].access_config[0].nat_ip}"
  })
  depends_on = [
    google_compute_instance.k8s_master_node
  ]
}