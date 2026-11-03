resource "aws_s3_bucket" "images" {
  bucket        = "minbucket-${var.kandidatnummer}"
  force_destroy = true
}
