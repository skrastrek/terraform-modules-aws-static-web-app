variable "name_prefix" {
  type = string
}

variable "acm_certificate_arn_us_east_1" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "domain_name_zone_id" {
  type = string
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "spa_enabled" {
  type        = bool
  description = "Enable or disable SPA-specific features."
}

variable "spa_custom_error_response_codes" {
  type = list(number)
}

variable "auth_default_cache_behaviour" {
  type = object({
    lambda_arn   = string
    event_type   = optional(string, "viewer-request")
    include_body = optional(bool, false)
  })
  default = null
}

variable "auth_ordered_cache_behaviours" {
  type = list(object({
    path_pattern = string
    lambda_arn   = string
    event_type   = optional(string, "viewer-request")
    include_body = optional(bool, false)
  }))
  default = []
}

variable "custom_origins" {
  type = list(object({
    origin_id           = string
    origin_path         = optional(string, null)
    domain_name         = string
    connection_attempts = optional(number, null)
    connection_timeout  = optional(number, null)
    custom_origin_config = object({
      http_port                = number
      https_port               = number
      origin_protocol_policy   = string
      origin_ssl_protocols     = list(string)
      origin_keepalive_timeout = optional(number, null)
      origin_read_timeout      = optional(number, null)
    })
  }))
  default = []
}

variable "custom_ordered_cache_behaviours" {
  type = list(object({
    path_pattern     = string
    target_origin_id = string

    allowed_methods = list(string)
    cached_methods  = list(string)

    cache_policy_id            = string
    origin_request_policy_id   = optional(string, null)
    response_headers_policy_id = optional(string, null)

    compress = optional(bool, false)

    viewer_protocol_policy = string

    function_associations = optional(
      list(
        object({
          event_type   = string
          function_arn = string
        })
      ),
      []
    )

    lambda_function_associations = optional(
      list(
        object({
          lambda_arn   = string
          event_type   = optional(string, "viewer-request")
          include_body = optional(bool, false)
        }),
      ),
      []
    )
  }))
  default = []
}

variable "s3_bucket_ordered_cache_behaviours" {
  type = list(object({
    path_pattern = string

    allowed_methods = list(string)
    cached_methods  = list(string)

    cache_policy_id = string

    compress = optional(bool, false)

    viewer_protocol_policy = string

    function_associations = optional(
      list(
        object({
          event_type   = string
          function_arn = string
        })
      ),
      []
    )

    lambda_function_associations = optional(
      list(
        object({
          lambda_arn   = string
          event_type   = optional(string, "viewer-request")
          include_body = optional(bool, false)
        }),
      ),
      []
    )
  }))
  default = []
}

variable "web_acl_arn" {
  type    = string
  default = null
}

variable "tags" {
  type = map(string)
}
