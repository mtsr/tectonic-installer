/*
Copyright 2017 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

resource "google_compute_instance_template" "master-it" {
  name           = "${var.cluster_name}-master-it"
  region         = "${var.region}"
  machine_type   = "${var.machine_type}"
  can_ip_forward = false

  disk {
    source_image = "coreos-${var.cl_channel}"
    auto_delete  = true
    disk_type    = "${var.disk_type}"
    disk_size_gb = "${var.disk_size}"
  }

  network_interface {
    subnetwork = "${var.master_subnetwork_name}"

    access_config = {
      // Ephemeral IP
    }
  }

  tags = ["tectonic-masters"]

  metadata = {
    user-data = "${data.ignition_config.main.rendered}"
    sshKeys   = "core:${file(var.public_ssh_key)}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "master-igm" {
  count              = 1
  region             = "${var.region}"
  target_size        = "${var.instance_count}"
  name               = "${var.cluster_name}-master-igm-${count.index}"
  instance_template  = "${google_compute_instance_template.master-it.self_link}"
  target_pools       = ["${var.master_targetpool_self_link}"]
  base_instance_name = "${var.cluster_name}-master"

  named_port {
    name = "https"
    port = 443
  }
}
