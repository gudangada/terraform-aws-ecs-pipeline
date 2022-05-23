module "codepipeline_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["codepipeline"]

  context = module.this.context
}

resource "aws_s3_bucket" "default" {
  count         = module.this.enabled ? 1 : 0
  bucket        = module.codepipeline_label.id
  acl           = "private"
  force_destroy = var.s3_bucket_force_destroy
  tags          = module.codepipeline_label.tags
}

module "codepipeline_assume_role_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["codepipeline", "assume"]

  context = module.this.context
}

resource "aws_iam_role" "default" {
  count              = module.this.enabled ? 1 : 0
  name               = module.codepipeline_assume_role_label.id
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = module.this.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.default.*.arn)
}

resource "aws_iam_policy" "default" {
  count  = module.this.enabled ? 1 : 0
  name   = module.codepipeline_label.id
  policy = data.aws_iam_policy_document.default.json
}

data "aws_iam_policy_document" "default" {
  statement {
    sid = ""

    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*",
      "iam:PassRole"
    ]

    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "s3" {
  count      = module.this.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.s3.*.arn)
}

module "codepipeline_s3_policy_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["codepipeline", "s3"]

  context = module.this.context
}

resource "aws_iam_policy" "s3" {
  count  = module.this.enabled ? 1 : 0
  name   = module.codepipeline_s3_policy_label.id
  policy = join("", data.aws_iam_policy_document.s3.*.json)
}

data "aws_iam_policy_document" "s3" {
  count = module.this.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]

    resources = [
      join("", aws_s3_bucket.default.*.arn),
      "${join("", aws_s3_bucket.default.*.arn)}/*"
    ]

    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = module.this.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
}

module "codebuild_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["codebuild"]

  context = module.this.context
}

resource "aws_iam_policy" "codebuild" {
  count  = module.this.enabled ? 1 : 0
  name   = module.codebuild_label.id
  policy = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid = ""

    actions = [
      "codebuild:*"
    ]

    resources = [
      module.codebuild.project_id
    ]

    effect = "Allow"
  }
}

# https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-permissions.html
resource "aws_iam_role_policy_attachment" "codestar" {
  count      = module.this.enabled && var.codestar_connection_arn != "" ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.codestar.*.arn)
}

module "codestar_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  enabled    = module.this.enabled && var.codestar_connection_arn != ""
  attributes = ["codestar"]

  context = module.this.context
}

resource "aws_iam_policy" "codestar" {
  count  = module.this.enabled && var.codestar_connection_arn != "" ? 1 : 0
  name   = module.codestar_label.id
  policy = join("", data.aws_iam_policy_document.codestar.*.json)
}

data "aws_iam_policy_document" "codestar" {
  count = module.this.enabled && var.codestar_connection_arn != "" ? 1 : 0
  statement {
    sid = ""

    actions = [
      "codestar-connections:UseConnection"
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "codestar-connections:FullRepositoryId"
      values = [
        format("%s/%s", var.repo_owner, var.repo_name)
      ]
    }

    resources = [var.codestar_connection_arn]
    effect    = "Allow"

  }
}

data "aws_caller_identity" "default" {
}

data "aws_region" "default" {
}

module "codebuild" {
  source                                = "cloudposse/codebuild/aws"
  version                               = "0.36.0"
  build_image                           = var.build_image
  build_compute_type                    = var.build_compute_type
  build_timeout                         = var.build_timeout
  buildspec                             = var.buildspec
  delimiter                             = module.this.delimiter
  attributes                            = ["build"]
  privileged_mode                       = var.privileged_mode
  aws_region                            = var.region != "" ? var.region : data.aws_region.default.name
  aws_account_id                        = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.default.account_id
  image_repo_name                       = var.image_repo_name
  image_tag                             = var.image_tag
  github_token                          = var.github_oauth_token
  environment_variables                 = var.environment_variables
  badge_enabled                         = var.badge_enabled
  cache_type                            = var.cache_type
  local_cache_modes                     = var.local_cache_modes
  secondary_artifact_location           = var.secondary_artifact_bucket_id
  secondary_artifact_identifier         = var.secondary_artifact_identifier
  secondary_artifact_encryption_enabled = var.secondary_artifact_encryption_enabled
  vpc_config                            = var.codebuild_vpc_config
  cache_bucket_suffix_enabled           = var.cache_bucket_suffix_enabled

  context = module.this.context
}

resource "aws_iam_role_policy_attachment" "codebuild_s3" {
  count      = module.this.enabled ? 1 : 0
  role       = module.codebuild.role_id
  policy_arn = join("", aws_iam_policy.s3.*.arn)
}

data "aws_ecr_repository" "default" {
  count = module.this.enabled && var.image_repo_name != "" ? 1 : 0
  name  = var.image_repo_name
}

data "aws_iam_policy_document" "ecr" {
  count = module.this.enabled && var.image_repo_name != "" ? 1 : 0

  statement {
    sid = ""

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      join("", data.aws_ecr_repository.default.*.arn)
    ]

    effect = "Allow"
  }
}


module "codepipeline_ecr_policy_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["codepipeline", "ecr"]

  context = module.this.context
}

resource "aws_iam_policy" "ecr" {
  count  = module.this.enabled && var.image_repo_name != "" ? 1 : 0
  name   = module.codepipeline_ecr_policy_label.id
  policy = join("", data.aws_iam_policy_document.ecr.*.json)
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr" {
  count      = module.this.enabled && var.image_repo_name != "" ? 1 : 0
  role       = module.codebuild.role_id
  policy_arn = join("", aws_iam_policy.ecr.*.arn)
}

## CodeDeploy Module ###
data "aws_iam_policy_document" "codedeploy" {
  statement {
    sid = ""

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetDeploymentConfig",
      "ecs:RegisterTaskDefinition"
    ]

    resources = [
      "arn:aws:codedeploy:${local.region}:${local.aws_account_id}:deploymentgroup:${local.codedeploy_app_name}/${local.codedeploy_config_name}",
      "arn:aws:codedeploy:${local.region}:${local.aws_account_id}:application:${local.codedeploy_app_name}",
      "arn:aws:codedeploy:${local.region}:${local.aws_account_id}:deploymentconfig:${local.codedeploy_config_name}"
    ]

    effect = "Allow"
  }
}

module "codedeploy_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["codedeploy"]

  context = module.this.context
}

resource "aws_iam_policy" "codedeploy" {
  count  = local.codedeploy_count
  name   = module.codedeploy_label.id
  policy = join("", data.aws_iam_policy_document.codedeploy.*.json)
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  count      = local.codedeploy_count
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.codedeploy.*.arn)
}

resource "aws_iam_role_policy_attachment" "codedeploy_role" {
  count      = local.codedeploy_count
  policy_arn = "arn:${join("", data.aws_partition.current.*.partition)}:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = join("", aws_iam_role.default.*.id)
}

data "aws_partition" "current" {
  count = local.codedeploy_count
}

module "codedeploy" {
  source = "git::https://github.com/gudangada/terraform-aws-code-deploy"

  count                              = local.codedeploy_count
  minimum_healthy_hosts              = var.minimum_healthy_hosts
  traffic_routing_config             = var.traffic_routing_config
  alarm_configuration                = var.alarm_configuration
  auto_rollback_configuration_events = var.auto_rollback_configuration_events
  blue_green_deployment_config       = var.blue_green_deployment_config
  deployment_style                   = var.deployment_style
  load_balancer_info                 = var.load_balancer_info
  service_role_arn                   = join("", aws_iam_role.default.*.arn)

  ecs_service = [
    {
      cluster_name = var.ecs_cluster_name
      service_name = var.service_name
    }
  ]

  context = module.this.context
}
## CodeDeploy Module ###

resource "aws_codepipeline" "default" {
  count    = module.this.enabled && var.github_oauth_token != "" ? 1 : 0
  name     = module.codepipeline_label.id
  role_arn = join("", aws_iam_role.default.*.arn)

  artifact_store {
    location = join("", aws_s3_bucket.default.*.bucket)
    type     = "S3"
  }

  depends_on = [
    aws_iam_role_policy_attachment.default,
    aws_iam_role_policy_attachment.s3,
    aws_iam_role_policy_attachment.codebuild,
    aws_iam_role_policy_attachment.codebuild_s3,
    aws_iam_role_policy_attachment.codedeploy,
    aws_iam_role_policy_attachment.codebuild_ecr,
    aws_iam_role_policy_attachment.codedeploy_role
  ]

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration = {
        OAuthToken           = var.github_oauth_token
        Owner                = var.repo_owner
        Repo                 = var.repo_name
        Branch               = var.branch
        PollForSourceChanges = var.poll_source_changes
      }
    }
  }

  dynamic "stage" {
    for_each = var.disable_approval_before_build ? [] : [1]
    content {
      name = "Approval"

      action {
        name     = "Approval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["code"]
      output_artifacts = ["task"]

      configuration = {
        ProjectName = module.codebuild.project_name
      }
    }
  }

  dynamic "stage" {
    for_each = var.use_codedeploy_for_deployment ? [] : [1]
    content {
      name = "Deploy"

      action {
        name     = "Deploy"
        category = "Deploy"
        owner    = "AWS"
        provider = "ECS"
        version  = "1"

        input_artifacts = ["task"]

        configuration = {
          ClusterName = var.ecs_cluster_name
          ServiceName = var.service_name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.use_codedeploy_for_deployment ? [1] : []
    content {
      name = "Deploy"

      action {
        name     = "Deploy"
        category = "Deploy"
        owner    = "AWS"
        provider = "CodeDeployToECS"
        version  = "1"

        input_artifacts = ["task"]

        configuration = {
          ApplicationName                = join("", module.codedeploy.*.name)
          DeploymentGroupName            = join("", module.codedeploy.*.group_name)
          Image1ArtifactName             = "task"
          Image1ContainerName            = "IMAGE1_NAME"
          AppSpecTemplateArtifact        = "task"
          AppSpecTemplatePath            = "appspec.yml"
          TaskDefinitionTemplateArtifact = "task"
          TaskDefinitionTemplatePath     = "taskdef.json"
        }
      }
    }
  }

  lifecycle {
    # prevent github OAuthToken from causing updates, since it's removed from state file
    ignore_changes = [stage[0].action[0].configuration]
  }
}

# https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodestarConnectionSource.html#action-reference-CodestarConnectionSource-example
resource "aws_codepipeline" "bitbucket" {
  count    = module.this.enabled && var.codestar_connection_arn != "" ? 1 : 0
  name     = module.codepipeline_label.id
  role_arn = join("", aws_iam_role.default.*.arn)

  artifact_store {
    location = join("", aws_s3_bucket.default.*.bucket)
    type     = "S3"
  }

  depends_on = [
    aws_iam_role_policy_attachment.default,
    aws_iam_role_policy_attachment.s3,
    aws_iam_role_policy_attachment.codebuild,
    aws_iam_role_policy_attachment.codebuild_s3,
    aws_iam_role_policy_attachment.codestar,
    aws_iam_role_policy_attachment.codedeploy
  ]

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["code"]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = format("%s/%s", var.repo_owner, var.repo_name)
        BranchName           = var.branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["code"]
      output_artifacts = ["task"]

      configuration = {
        ProjectName = module.codebuild.project_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["task"]
      version         = "1"

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.service_name
      }
    }
  }
}

resource "random_string" "webhook_secret" {
  count  = module.this.enabled && var.webhook_enabled ? 1 : 0
  length = 32

  # Special characters are not allowed in webhook secret (AWS silently ignores webhook callbacks)
  special = false
}

locals {
  region         = var.region != "" ? var.region : data.aws_region.default.name
  aws_account_id = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.default.account_id

  codedeploy_count       = module.this.enabled && var.use_codedeploy_for_deployment ? 1 : 0
  codedeploy_app_name    = join("", module.codedeploy.*.name)
  codedeploy_config_name = join("", module.codedeploy.*.deployment_config_name)

  webhook_secret = join("", random_string.webhook_secret.*.result)
  webhook_url    = join("", aws_codepipeline_webhook.webhook.*.url)
}

resource "aws_codepipeline_webhook" "webhook" {
  count           = module.this.enabled && var.webhook_enabled ? 1 : 0
  name            = module.codepipeline_label.id
  authentication  = var.webhook_authentication
  target_action   = var.webhook_target_action
  target_pipeline = join("", aws_codepipeline.default.*.name)

  authentication_configuration {
    secret_token = local.webhook_secret
  }

  filter {
    json_path    = var.webhook_filter_json_path
    match_equals = var.webhook_filter_match_equals
  }
}

module "github_webhooks" {
  source  = "cloudposse/repository-webhooks/github"
  version = "0.12.0"

  enabled              = module.this.enabled && var.webhook_enabled ? true : false
  github_organization  = var.repo_owner
  github_repositories  = [var.repo_name]
  github_token         = var.github_webhooks_token
  webhook_url          = local.webhook_url
  webhook_secret       = local.webhook_secret
  webhook_content_type = "json"
  events               = var.github_webhook_events

  context = module.this.context
}
