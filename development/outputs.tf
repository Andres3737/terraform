output "dns_publica_servidor_1" {
  description = "DNS publica del servidor 1"
  value       = "http://${aws_instance.mi_servidor_1.public_dns}:8080"

}


output "dns_publica_servidor_2" {
  description = "DNS publica del servidor 2"
  value       = "http://${aws_instance.mi_servidor_2.public_dns}:8080"

}

output "dns_load_balancer" {
  description = "DNS publica del Load Balancer"
  value       = "http://${aws_lb.alb.dns_name}"  
  
}

#output "ipv4_publica" {
#  description = "IPv4 publica del servidor"
#  value       = aws_instance.mi_servidor.public_ip
#}