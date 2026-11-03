variable "region" {
  description = "AWS-region"
  type        = string
  default     = "eu-west-1"
}

variable "kandidatnummer" {
  description = "Kandidatnummer, brukes i navn for å gjøre ressursene unike"
  type        = string
  default     = "62"
}

variable "image_tag" {
  description = "Tag på imaget i ECR som skal deployes (kort commit-SHA)"
  type        = string
}
