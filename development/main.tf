# -------------------------
# Define el provider de AWS
# -------------------------
provider "aws" {
  region = "us-east-1"
}

data "aws_subnet" "az_a" {
    availability_zone = "us-east-1a"
  }

data "aws_subnet" "az_b" {
    availability_zone = "us-east-1b"
  }

# ---------------------------------------
# Define una instancia EC2 con AMI Ubuntu
# ---------------------------------------

resource "aws_instance" "mi_servidor_1" {
  ami                    = "ami-04a81a99f5ec58529"
  instance_type          = "t2.micro"
  subnet_id = data.aws_subnet.az_a.id
  vpc_security_group_ids = [aws_security_group.mi_grupo_de_seguridad.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello Terraformers! soy servidor 1" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF 

  tags = {
    Name = "servidor-1"
  }
}

resource "aws_instance" "mi_servidor_2" {
  ami                    = "ami-04a81a99f5ec58529"
  instance_type          = "t2.micro"
  subnet_id = data.aws_subnet.az_b.id
  vpc_security_group_ids = [aws_security_group.mi_grupo_de_seguridad.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello Terraformers! soy servidor 2" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF 

  tags = {
    Name = "servidor-2"
  }
}


# ------------------------------------------------------
# Define un grupo de seguridad con acceso al puerto 8080
# ------------------------------------------------------

resource "aws_security_group" "mi_grupo_de_seguridad" {
  name = "primer-servidor-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    security_groups = [aws_security_group.alb.id]
    description = "Acceso al puerto 8080 desde el exterior"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
}


# ----------------------------------------
# Load Balancer público con dos instancias
# ----------------------------------------
resource "aws_lb" "alb" { 
  load_balancer_type = "application" 
  name = "terraformer-alb" 
  security_groups = [aws_security_group.alb.id] 
  subnets = [data.aws_subnet.az_a.id, data.aws_subnet.az_b.id] 
}


# ------------------------------------
# Security group para el Load Balancer
# ------------------------------------
resource "aws_security_group" "alb" {
  name = "alb-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 80 desde el exterior"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 8080 de nuestros servidores"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
  
}

# ----------------------------------------------------
# Data Source para obtener el ID de la VPC por defecto
# ----------------------------------------------------
data "aws_vpc" "default" {
  default = true
}


# ----------------------------------
# Target Group para el Load Balancer
# ----------------------------------
resource "aws_lb_target_group" "this" { 
  name = "terraformer-alb-target-group" 
  port = 80
  protocol = "HTTP" 
  vpc_id = data.aws_vpc.default.id

  health_check {
    enabled = true
    matcher = "200"
    path = "/"
    port = "8080"
    protocol = "HTTP"
  } 
}


# -----------------------------
# Attachment para el servidor 1
# -----------------------------
resource "aws_lb_target_group_attachment" "servidor_1" { 
  target_group_arn = aws_lb_target_group.this.arn 
  target_id = aws_instance.mi_servidor_1.id 
  port = 8080
}


# -----------------------------
# Attachment para el servidor 2
# -----------------------------
resource "aws_lb_target_group_attachment" "servidor_2" { 
  target_group_arn = aws_lb_target_group.this.arn 
  target_id = aws_instance.mi_servidor_2.id 
  port = 8080
}


# ------------------------
# Listener para nuestro LB
# ------------------------
resource "aws_lb_listener" "this" { 
  load_balancer_arn = aws_lb.alb.arn 
  port = 80
  protocol = "HTTP" 

  default_action { 
    target_group_arn = aws_lb_target_group.this.arn 
    type = "forward" 
  } 
  
}