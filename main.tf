provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_policy" {
  name        = "ecs_policy"
  description = "ECS permissions policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeRepositories",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecs:CreateCluster",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeCluster",
          "ecs:DescribeTaskDefinition",
          "ecs:ListClusters",
          "ecs:ListTaskDefinitions",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:CreateService",
          "ecs:DeleteService",
          "ecs:ListServices",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attachment" {
  policy_arn = aws_iam_policy.ecs_policy.arn
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_ecr_repository" "fn_expense_service_repository" {
  name = "fn-expense-service-repository"
}

resource "aws_ecs_cluster" "fn_expense_service_ecs_cluster" {
  name = "fn-expense-service-ecs-cluster"
}

# resource "aws_subnet" "fn_expense_service_subnet" {
#   vpc_id                  = "vpc-094cd8b8f482f8bb0" # Change it to a variable if needed
#   cidr_block              = "172.31.0.0/16"  # Specify your preferred CIDR block
#   availability_zone       = "us-east-1a"  # Replace with your desired AZ
# }

resource "aws_ecs_task_definition" "fn_expense_service_task_definition" {
  family                   = "fn-expense-service-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn        = aws_iam_role.ecs_execution_role.arn

  cpu    = "256" # Quarter vCPU
  memory = "512" # MiB

  container_definitions = jsonencode([{
    name      = "my-app",
    image     = aws_ecr_repository.fn_expense_service_repository.repository_url,
    memory    = 512,
    cpu       = 256,
    essential = true,
    portMappings = [{
      containerPort = 4000,
      hostPort      = 4000
    }]
  }])
}

# resource "aws_ecs_service" "fn_expense_ecs_service" {
#   name            = "fn-expense-ecs-service"
#   task_definition = aws_ecs_task_definition.fn_expense_service_task_definition.arn
#   launch_type     = "FARGATE"
#   desired_count   = 1

#   network_configuration {
#     subnets = [subnet-0122b8922363a20d9] #Hardcoding replace it with aws_subnet.fn_expense_service_subnet.id
#   }
# }

# resource "aws_lb" "fn_expense_service_alb" {
#   name               = "fn-expense-service-alb"
#   internal           = false
#   load_balancer_type = "application"
#   enable_deletion_protection = false
#   security_groups    = [aws_security_group.fn_expense_service_security_group.id]
#   subnets            = [subnet-0122b8922363a20d9] #Hardcoding replace it with aws_subnet.fn_expense_service_subnet.id

#   enable_http2 = true
# }

# resource "aws_lb_target_group" "fn_expense_service_target_group" {
#   name     = "fn-expense-service-target-group"
#   port     = 80
#   protocol = "HTTP" # Needs to be changed to HTTPS, check with your team for SSL certificate
#   vpc_id   = "vpc-094cd8b8f482f8bb0" # Change it to a variable if needed
# }

# resource "aws_security_group" "fn_expense_service_security_group" {
#   name        = "fn-expense-service-sg"
#   description = "My App Security Group"

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443           # Allow incoming traffic on port 443 (HTTPS)
#     to_port     = 443
#     protocol    = "tcp"         # Allow TCP traffic
#     cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any source (0.0.0.0/0)
#   }

#   # Commented out ingress rule for port 80 (HTTP)
#   # ingress {
#   #   from_port   = 80
#   #   to_port     = 80
#   #   protocol    = "tcp"
#   #   cidr_blocks = ["0.0.0.0/0"]
#   # }
# }
