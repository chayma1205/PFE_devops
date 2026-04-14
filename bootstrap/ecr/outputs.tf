output "backend_repo_url" {
  description = "Backend ECR repository URL (used to push/pull images)"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repo_url" {
  description = "Frontend ECR repository URL (used to push/pull images)"
  value       = aws_ecr_repository.frontend.repository_url
}
