module "foundation" {
  source = "./modules/foundation"

  name_prefix               = local.name_prefix
  tags                      = local.tags
  aws_region                = var.aws_region
  account_id                = data.aws_caller_identity.current.account_id
  vpc_cidr                  = var.vpc_cidr
  azs                       = var.azs
  backend_container_port    = var.backend_container_port
  public_subnet_cidrs       = local.public_subnet_cidrs
  firewall_subnet_cidrs     = local.firewall_subnet_cidrs
  private_app_subnet_cidrs  = local.private_app_subnet_cidrs
  private_data_subnet_cidrs = local.private_data_subnet_cidrs
}

module "data" {
  source = "./modules/data"

  name_prefix                = local.name_prefix
  tags                       = local.tags
  enable_dms                 = var.enable_dms
  account_id                 = data.aws_caller_identity.current.account_id
  kms_key_arn                = module.foundation.kms_key_arn
  private_app_subnet_ids     = module.foundation.private_app_subnet_ids
  private_data_subnet_ids    = module.foundation.private_data_subnet_ids
  efs_security_group_id      = module.foundation.efs_security_group_id
  docdb_security_group_id    = module.foundation.docdb_security_group_id
  documentdb_master_username = var.documentdb_master_username
  documentdb_instance_class  = var.documentdb_instance_class
  documentdb_instance_count  = var.documentdb_instance_count
}

module "app" {
  source = "./modules/app"

  name_prefix                            = local.name_prefix
  tags                                   = local.tags
  aws_region                             = var.aws_region
  app_origin                             = var.app_origin
  google_client_id                       = var.google_client_id
  ai_microservice_url                    = var.ai_microservice_url
  backend_container_port                 = var.backend_container_port
  backend_cpu                            = var.backend_cpu
  backend_memory                         = var.backend_memory
  backend_desired_count                  = var.backend_desired_count
  bedrock_model_id                       = var.bedrock_model_id
  documentdb_database_name               = var.documentdb_database_name
  ops_runner_instance_type               = var.ops_runner_instance_type
  enable_dms                             = var.enable_dms
  mongodb_atlas_auth_source              = var.mongodb_atlas_auth_source
  dms_migration_type                     = var.dms_migration_type
  kms_key_arn                            = module.foundation.kms_key_arn
  vpc_id                                 = module.foundation.vpc_id
  private_app_subnet_ids                 = module.foundation.private_app_subnet_ids
  alb_security_group_id                  = module.foundation.alb_security_group_id
  ecs_security_group_id                  = module.foundation.ecs_security_group_id
  api_gateway_vpc_link_security_group_id = module.foundation.api_gateway_vpc_link_security_group_id
  dms_security_group_id                  = module.foundation.dms_security_group_id
  ops_runner_security_group_id           = module.foundation.ops_runner_security_group_id
  efs_id                                 = module.data.efs_id
  efs_arn                                = module.data.efs_arn
  media_bucket                           = module.data.media_bucket
  media_bucket_arn                       = module.data.media_bucket_arn
  knowledge_base_source_bucket           = module.data.knowledge_base_source_bucket
  knowledge_base_source_bucket_arn       = module.data.knowledge_base_source_bucket_arn
  app_runtime_secret_arn                 = module.data.app_runtime_secret_arn
  mongodb_atlas_secret_arn               = module.data.mongodb_atlas_secret_arn
  documentdb_master_secret_arn           = module.data.documentdb_master_secret_arn
  documentdb_cluster_arn                 = module.data.documentdb_cluster_arn
  cognito_user_pool_id                   = module.data.cognito_user_pool_id
  cognito_user_pool_client_id            = module.data.cognito_user_pool_client_id
}

module "frontend" {
  source = "./modules/frontend"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix                    = local.name_prefix
  tags                           = local.tags
  account_id                     = data.aws_caller_identity.current.account_id
  create_cloudfront_distribution = var.create_cloudfront_distribution
  api_endpoint                   = module.app.http_api_api_endpoint

  depends_on = [module.app]
}
