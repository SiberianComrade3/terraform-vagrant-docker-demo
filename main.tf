# Local ISP address: 'curl ifconfig.ru'
data "external" "get_isp_source_address" {
  program = ["/bin/bash", "${path.module}/scripts/get_my_ip.sh"]
}

# Verify: openstack volume list
data "openstack_images_image_v2" "boot_image" {
  name        = var.linux_image_name
  visibility  = "public"
  most_recent = true
}

resource "openstack_blockstorage_volume_v3" "boot_volume_1" {
  name                 = "tf_host-volume-1"
  size                 = "15"
  image_id             = data.openstack_images_image_v2.boot_image.id
  volume_type          = var.volume_type
  availability_zone    = var.server_zone
  enable_online_resize = true
  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_flavor_v2" "host_flavor" {
  name      = "tf_host_flavor"
  ram       = 2048
  vcpus     = 2
  disk      = 0
  is_public = false
}

# Verify: openstack network list
resource "openstack_networking_network_v2" "network_1" {
  name     = "tf_network_1"
  external = false
}

# Verify: openstack subnet list, openstack subnet show <name>
resource "openstack_networking_subnet_v2" "subnet_1" {
  network_id = openstack_networking_network_v2.network_1.id
  #  dns_nameservers = var.dns_nameservers
  name       = var.subnet_cidr
  cidr       = var.subnet_cidr
  no_gateway = false
}

resource "openstack_networking_port_v2" "network_port_1" {
  name       = "tf-astra-host-eth0"
  network_id = openstack_networking_network_v2.network_1.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet_1.id
  }
}

# Network
data "openstack_networking_network_v2" "external_net" {
  name     = "external-network"
  external = true
}

# Verify: openstack router list, openstack router show tf_router_1
resource "openstack_networking_router_v2" "router_1" {
  name                = "tf-router-1"
  external_network_id = data.openstack_networking_network_v2.external_net.id
  admin_state_up      = true
}

# Attach router to private subnet
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_compute_instance_v2" "linux_host" {
  name              = "tf-astra-host"
  image_id          = data.openstack_images_image_v2.boot_image.id
  flavor_id         = openstack_compute_flavor_v2.host_flavor.id
  key_pair          = openstack_compute_keypair_v2.infra_keypair.name
  availability_zone = var.server_zone
  user_data = templatefile(
    "${path.module}/templates/host-cloud-config.tftpl",
    {
      infra_private_key     = indent(6, openstack_compute_keypair_v2.infra_keypair.private_key),
      master_ip             = data.external.get_isp_source_address.result.my_ip,
      proctor_ip            = var.proctor_ip,
      vagrant_image_name    = var.vagrant_image_name,
      vagrant_image_version = var.vagrant_image_version,
      grafana_cert          = indent(6, tls_self_signed_cert.grafana_self_signed_cert.cert_pem),
      grafana_key           = indent(6, tls_private_key.infra_private_key.private_key_pem),
      vagrantfile = indent(6, templatefile(
        "${path.module}/templates/Vagrantfile.tftpl",
        {
          vagrant_image_name = var.vagrant_image_name
        }
        )
      ),
      guest_setup_yaml = indent(6, file("${path.module}/guest_setup.yaml")),
    }
  )

  network {
    port = openstack_networking_port_v2.network_port_1.id
  }

  block_device {
    uuid             = openstack_blockstorage_volume_v3.boot_volume_1.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }

  lifecycle {
    ignore_changes = [image_id]
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}

# Acquire Public IP for Linux host
resource "openstack_networking_floatingip_v2" "ext_float_ip_host" {
  pool = "external-network"
}

# Associating External floating IP to Bastion server
resource "openstack_compute_floatingip_associate_v2" "float_ip_host_assoc" {
  depends_on = [
    openstack_networking_network_v2.network_1
  ]
  floating_ip = openstack_networking_floatingip_v2.ext_float_ip_host.address
  instance_id = openstack_compute_instance_v2.linux_host.id
}
