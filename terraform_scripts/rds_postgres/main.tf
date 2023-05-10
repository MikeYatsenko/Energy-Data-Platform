resource "aws_security_group" "RDSSecurity" {
  name        = "RDSSecurity"
  description = "Connection to RDS"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create RDS Database
resource "aws_db_instance" "RDSDatabase" {
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "13.7"
  username               = "mikeyatsenko"
  password               = "yatsenkomike31"
  publicly_accessible    = true
  skip_final_snapshot    = true
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [aws_security_group.RDSSecurity.id]
}