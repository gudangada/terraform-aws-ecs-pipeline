variable "ecs_cluster_name" {
  type        = string
  description = "ECS Cluster Name"
}

variable "service_name" {
  type        = string
  description = "ECS Service Name"
}

variable "github_oauth_token" {
  type        = string
  description = "GitHub OAuth Token with permissions to access private repositories"
  default     = ""
}

variable "github_webhooks_token" {
  type        = string
  default     = ""
  description = "GitHub OAuth Token with permissions to create webhooks. If not provided, can be sourced from the `GITHUB_TOKEN` environment variable"
}

variable "github_webhook_events" {
  type        = list(string)
  description = "A list of events which should trigger the webhook. See a list of [available events](https://developer.github.com/v3/activity/events/types/)"
  default     = ["push"]
}

variable "repo_owner" {
  type        = string
  description = "GitHub Organization or Username"
}

variable "repo_name" {
  type        = string
  description = "GitHub repository name of the application to be built and deployed to ECS"
}

variable "branch" {
  type        = string
  description = "Branch of the GitHub repository, _e.g._ `master`"
}

variable "badge_enabled" {
  type        = bool
  default     = false
  description = "Generates a publicly-accessible URL for the projects build badge. Available as badge_url attribute when enabled"
}

variable "build_image" {
  type        = string
  default     = "aws/codebuild/docker:17.09.0"
  description = "Docker image for build environment, _e.g._ `aws/codebuild/docker:docker:17.09.0`"
}

variable "build_compute_type" {
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  description = "`CodeBuild` instance size. Possible values are: `BUILD_GENERAL1_SMALL` `BUILD_GENERAL1_MEDIUM` `BUILD_GENERAL1_LARGE`"
}

variable "build_timeout" {
  type        = number
  default     = 60
  description = "How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
}

variable "buildspec" {
  type        = string
  default     = ""
  description = "Declaration to use for building the project. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)"
}

variable "secondary_artifact_bucket_id" {
  type        = string
  default     = null
  description = "Optional bucket for secondary artifact deployment. If specified, the buildspec must include a secondary artifacts section which controls the artifacts deployed to the bucket [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)"
}

variable "secondary_artifact_encryption_enabled" {
  type        = bool
  default     = false
  description = "If set to true, enable encryption on the secondary artifact bucket"
}

variable "secondary_artifact_identifier" {
  type        = string
  default     = null
  description = "Identifier for optional secondary artifact deployment. If specified, the identifier must appear in the buildspec as the name of the section which controls the artifacts deployed to the secondary artifact bucket [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)"
}


# https://www.terraform.io/docs/configuration/variables.html
# It is recommended you avoid using boolean values and use explicit strings
variable "poll_source_changes" {
  type        = bool
  default     = false
  description = "Periodically check the location of your source content and run the pipeline if changes are detected"
}

variable "privileged_mode" {
  type        = bool
  default     = false
  description = "If set to true, enables running the Docker daemon inside a Docker container on the CodeBuild instance. Used when building Docker images"
}

variable "region" {
  type        = string
  description = "AWS Region, e.g. us-east-1. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html)"
}

variable "aws_account_id" {
  type        = string
  default     = ""
  description = "AWS Account ID. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html)"
}

variable "image_repo_name" {
  type        = string
  description = "ECR repository name to store the Docker image built by this module. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html)"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag in the ECR repository, e.g. 'latest'. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html)"
}

variable "environment_variables" {
  type = list(object(
    {
      name  = string
      value = string
      type  = string
  }))

  default     = []
  description = "A list of maps, that contain the keys 'name', 'value', and 'type' to be used as additional environment variables for the build. Valid types are 'PLAINTEXT', 'PARAMETER_STORE', or 'SECRETS_MANAGER'"
}

variable "webhook_enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any webhook resources"
  default     = true
}

variable "webhook_target_action" {
  type        = string
  description = "The name of the action in a pipeline you want to connect to the webhook. The action must be from the source (first) stage of the pipeline"
  default     = "Source"
}

variable "webhook_authentication" {
  type        = string
  description = "The type of authentication to use. One of IP, GITHUB_HMAC, or UNAUTHENTICATED"
  default     = "GITHUB_HMAC"
}

variable "webhook_filter_json_path" {
  type        = string
  description = "The JSON path to filter on"
  default     = "$.ref"
}

variable "webhook_filter_match_equals" {
  type        = string
  description = "The value to match on (e.g. refs/heads/{Branch})"
  default     = "refs/heads/{Branch}"
}

variable "s3_bucket_force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects should be deleted from the CodePipeline artifact store S3 bucket so that the bucket can be destroyed without error"
  default     = false
}

variable "codestar_connection_arn" {
  type        = string
  description = "CodeStar connection ARN required for Bitbucket integration with CodePipeline"
  default     = ""
}

variable "cache_type" {
  type        = string
  default     = "S3"
  description = "The type of storage that will be used for the AWS CodeBuild project cache. Valid values: NO_CACHE, LOCAL, and S3.  Defaults to S3.  If cache_type is S3, it will create an S3 bucket for storing codebuild cache inside"
}

variable "cache_bucket_suffix_enabled" {
  type        = bool
  default     = true
  description = "The cache bucket generates a random 13 character string to generate a unique bucket name. If set to false it uses terraform-null-label's id value. It only works when cache_type is 'S3'"
}

variable "local_cache_modes" {
  type        = list(string)
  default     = []
  description = "Specifies settings that AWS CodeBuild uses to store and reuse build dependencies. Valid values: LOCAL_SOURCE_CACHE, LOCAL_DOCKER_LAYER_CACHE, and LOCAL_CUSTOM_CACHE"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#vpc_config
variable "codebuild_vpc_config" {
  type        = any
  default     = {}
  description = "Configuration for the builds to run inside a VPC."
}

variable "disable_approval_before_build" {
  type        = bool
  default     = false
  description = "Boolean to enable or disable manual approval before build"
}

variable "use_codedeploy_for_deploy_stage" {
  type        = bool
  default     = false
  description = "Boolean to enable codepipeline to use CodeDeploy as deployment provider"
}

variable "compute_platform" {
  type        = string
  default     = "ECS"
  description = "The compute platform can either be `ECS`, `Lambda`, or `Server`"
}

variable "minimum_healthy_hosts" {
  type = object({
    type  = string
    value = number
  })
  default     = null
  description = <<-DOC
    type:
      The type can either be `FLEET_PERCENT` or `HOST_COUNT`.
    value:
      The value when the type is `FLEET_PERCENT` represents the minimum number of healthy instances 
      as a percentage of the total number of instances in the deployment.
      When the type is `HOST_COUNT`, the value represents the minimum number of healthy instances as an absolute value.
  DOC
}

variable "traffic_routing_config" {
  type = object({
    type       = string
    interval   = number
    percentage = number
  })
  default     = null
  description = <<-DOC
    type:
      Type of traffic routing config. One of `TimeBasedCanary`, `TimeBasedLinear`, `AllAtOnce`.
    interval:
      The number of minutes between the first and second traffic shifts of a deployment.
    percentage:
      The percentage of traffic to shift in the first increment of a deployment.
  DOC
}

variable "create_default_service_role" {
  type        = bool
  default     = true
  description = "Whether to create default IAM role ARN that allows deployments."
}

variable "service_role_arn" {
  type        = string
  default     = null
  description = "The service IAM role ARN that allows deployments."
}

variable "create_default_sns_topic" {
  type        = bool
  default     = true
  description = "Whether to create default SNS topic through which notifications are sent."
}

variable "sns_topic_arn" {
  type        = string
  default     = null
  description = "The ARN of the SNS topic through which notifications are sent."
}

variable "autoscaling_groups" {
  type        = list(string)
  description = "A list of Autoscaling Groups associated with the deployment group."
  default     = []
}

variable "alarm_configuration" {
  type = object({
    alarms                    = list(string)
    ignore_poll_alarm_failure = bool
  })
  default     = null
  description = <<-DOC
     Configuration of deployment to stop when a CloudWatch alarm detects that a metric has fallen below or exceeded a defined threshold.
      alarms:
        A list of alarms configured for the deployment group.
      ignore_poll_alarm_failure:
        Indicates whether a deployment should continue if information about the current state of alarms cannot be retrieved from CloudWatch.
  DOC
}

variable "auto_rollback_configuration_events" {
  type        = string
  default     = "DEPLOYMENT_FAILURE"
  description = "The event type or types that trigger a rollback. Supported types are `DEPLOYMENT_FAILURE` and `DEPLOYMENT_STOP_ON_ALARM`."
}

variable "blue_green_deployment_config" {
  type        = any
  default     = null
  description = <<-DOC
    Configuration block of the blue/green deployment options for a deployment group, 
    see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group#blue_green_deployment_config
  DOC
}

variable "deployment_style" {
  type = object({
    deployment_option = string
    deployment_type   = string
  })
  default     = null
  description = <<-DOC
    Configuration of the type of deployment, either in-place or blue/green, 
    you want to run and whether to route deployment traffic behind a load balancer.
    deployment_option:
      Indicates whether to route deployment traffic behind a load balancer. 
      Possible values: `WITH_TRAFFIC_CONTROL`, `WITHOUT_TRAFFIC_CONTROL`.
    deployment_type:
      Indicates whether to run an in-place deployment or a blue/green deployment.
      Possible values: `IN_PLACE`, `BLUE_GREEN`.
  DOC
}

variable "ec2_tag_filter" {
  type = set(object({
    key   = string
    type  = string
    value = string
  }))
  default     = []
  description = <<-DOC
    The Amazon EC2 tags on which to filter. The deployment group includes EC2 instances with any of the specified tags.
    Cannot be used in the same call as ec2TagSet.
  DOC
}

variable "ec2_tag_set" {
  type = set(object(
    {
      ec2_tag_filter = set(object(
        {
          key   = string
          type  = string
          value = string
        }
      ))
    }
  ))
  default     = []
  description = <<-DOC
    A list of sets of tag filters. If multiple tag groups are specified,
    any instance that matches to at least one tag filter of every tag group is selected.
    key:
      The key of the tag filter.
    type:
      The type of the tag filter, either `KEY_ONLY`, `VALUE_ONLY`, or `KEY_AND_VALUE`.
    value:
      The value of the tag filter.
  DOC
}

variable "ecs_service" {
  type = list(object({
    cluster_name = string
    service_name = string
  }))
  default     = null
  description = <<-DOC
    Configuration block(s) of the ECS services for a deployment group.
    cluster_name:
      The name of the ECS cluster. 
    service_name:
      The name of the ECS service.
  DOC
}

variable "load_balancer_info" {
  type        = map(any)
  default     = null
  description = <<-DOC
    Single configuration block of the load balancer to use in a blue/green deployment, 
    see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group#load_balancer_info
  DOC
}

variable "trigger_events" {
  type        = list(string)
  default     = ["DeploymentFailure"]
  description = <<-DOC
    The event type or types for which notifications are triggered. 
    Some values that are supported: 
      `DeploymentStart`, `DeploymentSuccess`, `DeploymentFailure`, `DeploymentStop`, 
      `DeploymentRollback`, `InstanceStart`, `InstanceSuccess`, `InstanceFailure`. 
    See the CodeDeploy documentation for all possible values.
    http://docs.aws.amazon.com/codedeploy/latest/userguide/monitoring-sns-event-notifications-create-trigger.html 
  DOC
}
