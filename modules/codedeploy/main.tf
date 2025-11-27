# ============================================================================
# CodeDeploy Application & Deployment Group
# ============================================================================

# 1. CodeDeploy Application - User Service
resource "aws_codedeploy_app" "user_app" {
  name             = "wealist-user-app-codeDeploy"
  compute_platform = "Server"

  tags = {
    Name      = "wealist-user-app-codeDeploy"
    Service   = "user"
    ManagedBy = "terraform"
  }
}

# 2. CodeDeploy Application - Board Service
resource "aws_codedeploy_app" "board_app" {
  name             = "wealist-board-app-codeDeploy"
  compute_platform = "Server"

  tags = {
    Name      = "wealist-board-app-codeDeploy"
    Service   = "board"
    ManagedBy = "terraform"
  }
}

# 3. Deployment Group - User Service (Primary)
resource "aws_codedeploy_deployment_group" "user_dg_primary" {
  app_name               = aws_codedeploy_app.user_app.name
  deployment_group_name  = "${var.name_prefix}-deploy-group"
  service_role_arn       = var.codedeploy_service_role_arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  # Auto Scaling Group 연결
  autoscaling_groups = [var.backend_asg_name]

  # 배포 스타일: In-Place with Traffic Control
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  # Auto Rollback 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  # ALB 타겟 그룹 연결
  load_balancer_info {
    target_group_info {
      name = var.user_target_group_name
    }
  }

  tags = {
    Name      = "${var.name_prefix}-deploy-group"
    Service   = "user"
    ManagedBy = "terraform"
  }
}

# 4. Deployment Group - User Service (Target Group)
resource "aws_codedeploy_deployment_group" "user_dg_tg" {
  app_name               = aws_codedeploy_app.user_app.name
  deployment_group_name  = "wealist-user-app-codeDeploy-tg"
  service_role_arn       = var.codedeploy_service_role_arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  # Auto Scaling Group 연결
  autoscaling_groups = [var.backend_asg_name]

  # 배포 스타일: In-Place with Traffic Control
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  # Auto Rollback 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  # ALB 타겟 그룹 연결
  load_balancer_info {
    target_group_info {
      name = var.user_target_group_name
    }
  }

  tags = {
    Name      = "wealist-user-app-codeDeploy-tg"
    Service   = "user"
    ManagedBy = "terraform"
  }
}

# 5. Deployment Group - Board Service (Primary)
resource "aws_codedeploy_deployment_group" "board_dg_primary" {
  app_name               = aws_codedeploy_app.board_app.name
  deployment_group_name  = "${var.name_prefix}-deploy-group"
  service_role_arn       = var.codedeploy_service_role_arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  # Auto Scaling Group 연결
  autoscaling_groups = [var.backend_asg_name]

  # 배포 스타일: In-Place with Traffic Control
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  # Auto Rollback 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  # ALB 타겟 그룹 연결
  load_balancer_info {
    target_group_info {
      name = var.board_target_group_name
    }
  }

  tags = {
    Name      = "${var.name_prefix}-deploy-group"
    Service   = "board"
    ManagedBy = "terraform"
  }
}

# 6. Deployment Group - Board Service (Target Group)
resource "aws_codedeploy_deployment_group" "board_dg_tg" {
  app_name               = aws_codedeploy_app.board_app.name
  deployment_group_name  = "wealist-board-app-codeDeploy-tg"
  service_role_arn       = var.codedeploy_service_role_arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  # Auto Scaling Group 연결
  autoscaling_groups = [var.backend_asg_name]

  # 배포 스타일: In-Place with Traffic Control
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  # Auto Rollback 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  # ALB 타겟 그룹 연결
  load_balancer_info {
    target_group_info {
      name = var.board_target_group_name
    }
  }

  tags = {
    Name      = "wealist-board-app-codeDeploy-tg"
    Service   = "board"
    ManagedBy = "terraform"
  }
}
