output "host_public_ip" {
  description = "Public IP address of Prometheus instance"
  value       = openstack_networking_floatingip_v2.ext_float_ip_host.address
}

output "inbound_access_from" {
  description = "Public IP address of my ISP"
  value       = data.external.get_isp_source_address.result.my_ip
}

output "proctor_ip" {
  description = "Public IP address of Proctor"
  value       = var.proctor_ip
}

output "ssh_private_key" {
  description = "Path to SSH private key to use in 'ssh -i <this value>'"
  value       = "${path.module}/${var.ssh_private_key}"
}

output "ssh_to_host" {
  description = "Suggested command to connect Infrastucture"
  value       = "ssh -q -o StrictHostKeyChecking=no -i ${path.module}/${var.ssh_private_key} root@${openstack_networking_floatingip_v2.ext_float_ip_host.address}"
}

output "grafana_url" {
  description = "Suggested URL to open Grafana page"
  value       = "https://${openstack_networking_floatingip_v2.ext_float_ip_host.address}:3000"
}
