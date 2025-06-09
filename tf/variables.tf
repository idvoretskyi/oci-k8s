variable "region" {
  type    = string
  default = "uk-london-1"
}

variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type    = string
  default = null
}

variable "fingerprint" {
  type    = string
  default = null
}

variable "private_key_path" {
  type    = string
  default = null
}

variable "cluster_name" {
  type    = string
  default = "oke-arm"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.32.1"
}

variable "node_count" {
  type    = number
  default = 3
}

variable "node_memory_gb" {
  type    = number
  default = 6
}

variable "node_ocpus" {
  type    = number
  default = 1
}
