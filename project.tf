################################################################
# Provider Configuration
################################################################

provider "aws"  {
  region     = "us-east-1"
  access_key = "AKIA3MOITSKDNJWT6Q7B"
  secret_key = "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"
}

variable "db_name" {
 
  default = "wordpress2"
    
}

################################################################

variable "db_user" {
    
  default = "wpuser"
    
}

################################################################

variable "db_pass" {
    
  default = "wpuser123"    
    
}

################################################################

variable "db_port" {
    
  default = 3306
    
}





################################################################
# vpc configuration
################################################################

resource "aws_vpc" "app" {
    
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "app"
  }
}

################################################################
# public - 1 subnet Creation
################################################################

resource "aws_subnet" "public1" {
    
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.16.0.0/19"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "app-public-1"
  }
}

################################################################
# public - 2 subnet Creation
################################################################

resource "aws_subnet" "public2" {
    
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.16.32.0/19"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  tags = {
    Name = "app-public-2"
  }
}


################################################################
# private - 1 subnet Creation
################################################################

resource "aws_subnet" "private1" {
    
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.16.64.0/19"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1c"
  tags = {
    Name = "app-private-1"
  }
    
}

################################################################
# private - 2 subnet Creation
################################################################

resource "aws_subnet" "private2" {

  vpc_id     = aws_vpc.app.id
  cidr_block = "172.16.96.0/19"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1d"
  tags = {
    Name = "app-private-2"
  }
}

################################################################
# Internet gateWay
################################################################

resource "aws_internet_gateway" "igw" {
    
  vpc_id = aws_vpc.app.id
  tags = {
    Name = "app-igw"
  }
}


################################################################
# Elastic Ip
################################################################

resource "aws_eip" "nat" {
  vpc      = true
  tags = {
    Name = "app-eip"
  }
}


################################################################
# Nat GateWay
################################################################

resource "aws_nat_gateway" "nat" {
    
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public2.id
  tags = {
    Name = "app-nat"
  }
}


################################################################
# public route table
################################################################

resource "aws_route_table" "public" {
    
  vpc_id = aws_vpc.app.id
    
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "app-public"
  }
    
}


################################################################
# private route table
################################################################

resource "aws_route_table" "private" {
    
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "app-private"
  }
    
}


################################################################
# public-1  to public route table
################################################################

resource "aws_route_table_association" "public1" {
    
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
    
}

################################################################
# public-2  to public route table
################################################################


resource "aws_route_table_association" "public2" {
    
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
    
}


################################################################
# private-1  to private route table
################################################################


resource "aws_route_table_association" "private1" {
    
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
    
}
################################################################
# private-2  to private route table
################################################################


resource "aws_route_table_association" "private2" {

  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id

}

################################################################
# uploading keypair
################################################################

################################################################
# uploading keypair
################################################################

resource "aws_key_pair" "app" {

  key_name   = "app"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiYVd+g6K4HxH8tliCLZ8nrHT05YQtp9IrcbUt0juWfdB8atlg0LuUlcPmiPEpTQmCI130nGR/N+zI6fC4fZyTnSavS4aGQUuHVGszwDuOT9mBCknvsIMKAqYr9PNZpwV8cS4p6JBkHnx6fr8iVHoe/4wKdA28Ovn4FhUtp1EkH2WooHQTWAiCgQV8FvOCZbSiIu6rQxmInS0grMTJx4U+DRn74uiOiaQQmSnN6sg1tmFl7cdH60WJsrOSsRM1fXL7BulYPFdKHzCy5yTI+9RlffONE5SFwzj7QeyDOXIAs1zymDTIaqroOD7/1K/fSh/+qi31L+dK2uHPfOX2sB8B root@ip-172-31-50-38.ec2.internal"
}


####################################################################
# bastion
####################################################################

resource "aws_security_group" "bastion" {
    
  name        = "bastion server access"
  description = "22 traffic only"
  vpc_id      = aws_vpc.app.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
     
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-bastion"
  }
    
}




####################################################################
# webserver
####################################################################

resource "aws_security_group" "webserver" {
    
  name        = "webserver access"
  description = "allows 80,443,22 traffic"
  vpc_id      = aws_vpc.app.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.bastion.id  ]
  }
    
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-webserver"
  }
    
}

####################################################################
# dbserver
####################################################################

resource "aws_security_group" "dbserver" {
    
  name        = "dbserver access"
  description = "allows 3306,22 traffic"
  vpc_id      = aws_vpc.app.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.webserver.id ]
  }
  
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.bastion.id  ]
  }
    
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-dbserver"
  }
    
}


####################################################################
# bastion server
####################################################################


resource "aws_instance" "bastion" {

  ami           = "ami-04d29b6f966df1537"
  instance_type = "t2.micro"
  key_name  = aws_key_pair.app.id
  subnet_id = aws_subnet.public2.id
  vpc_security_group_ids = [ aws_security_group.bastion.id ]
  tags = {
    Name = "app-bastion"
  }
    
}





####################################################################
# webserver server
####################################################################

resource "aws_instance" "webserver" {

  ami                    = "ami-0b8f7da52f6286dc4"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.app.id
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [ aws_security_group.webserver.id ]
  tags                   = {
                             Name = "app-webserver"
                           }
    
  provisioner "file" {
      
    content     = templatefile("wp-config.php.tmpl",{ 
                                db_name = var.db_name ,
                                db_user = var.db_user ,
                                db_pass = var.db_pass ,
                                db_port = var.db_port ,
                                db_host = aws_db_instance.db.address
                                } 
                              )
      
    destination = "/tmp/wp-config.php"

    connection {
      type        = "ssh"
        
      user        = "ec2-user"
      host        = aws_instance.webserver.private_ip
      private_key = file("app")

      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = "ec2-user"
      bastion_private_key = file("app")
    }
  }
    
  provisioner "remote-exec" {
    inline = [
     "sudo cp /tmp/wp-config.php /var/www/html/wp-config.php"
        ]
      
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.webserver.private_ip
      private_key = file("app")

      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = "ec2-user"
      bastion_private_key = file("app")
    }
  }
    
}





####################################################################
# db subent group
####################################################################




resource "aws_db_subnet_group" "app" {
    
  name       = "app"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.public2.id]

  tags = {
    Name = "app"
  }
}



####################################################################
# dbserver server
####################################################################



resource "aws_db_instance" "db" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t2.micro"
  backup_retention_period = 0
  max_allocated_storage   = 0
  availability_zone       = "us-east-1c"
  deletion_protection     = false
  multi_az                = false
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.app.id
  vpc_security_group_ids  = [ aws_security_group.dbserver.id ]
  skip_final_snapshot     = true
   
  name                    = var.db_name
  port                    = var.db_port
  username                = var.db_user
  password                = var.db_pass
    
    
  tags                    = {
                             Name = "app-webserver"
                           }
}
