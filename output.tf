output "webserver_ips" {
  value = [for vm in esxi_guest.webserver : vm.ip_address]
}

output "databaseserver_ip" {
  value = esxi_guest.databaseserver.ip_address
}
