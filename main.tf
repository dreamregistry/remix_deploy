terraform {
  #  backend "s3" {}

  required_providers {
    docker = {
      source  = "registry.terraform.io/kreuzwerker/docker"
      version = "~>3.0"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~>3.5"
    }
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "random" {}
provider "docker" {}
provider "aws" {}

locals {
  non_secret_env = {
    for k, v in var.dream_env : k => try(tostring(v), null)
  }

  non_secret_cleaned = {
    for k, v in local.non_secret_env : k => v if v != null
  }

  secret_env = {
    for k in var.dream_secrets : k => data.aws_ssm_parameter.secret_env[k].value
  }

  env = toset([
    for k, v in merge(local.non_secret_cleaned, local.secret_env, {
      REDIS_HOST = "host.docker.internal"
    }) : "${k}=${v}"
  ])
  port = split(":", var.root_url)[2]
}

data "aws_ssm_parameter" "secret_env" {
  for_each = var.dream_secrets
  name     = var.dream_env[each.key].key
}

resource "random_pet" "container_name" {}
resource "random_pet" "docker_network_name" {}


resource "docker_image" "oidc_sidecar" {
  name         = "public.ecr.aws/c5q9w4j6/oidc-sidecar:latest"
  keep_locally = true
}

resource "docker_network" "private_network" {
  name = "oidc-sidecar-${random_pet.docker_network_name.id}"
}

resource "docker_container" "oidc_sidecar" {
  name  = "oidc-sidecar-${random_pet.container_name.id}"
  image = docker_image.oidc_sidecar.image_id
  ports {
    internal = 8080
    external = local.port
  }
  env      = local.env
  must_run = true
  rm       = true
  networks_advanced {
    name = docker_network.private_network.name
  }
}
