# ECR private repository
resource "aws_ecr_repository" "backend" {
  name = "backend-todo"
  image_tag_mutability = "IMMUTABLE"
}

# ECR private repository
resource "aws_ecr_repository" "frontend" {
  name = "frontend-todo"
  image_tag_mutability = "IMMUTABLE"
}