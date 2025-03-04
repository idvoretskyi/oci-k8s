variable "oci_profile" {
  description = "OCI CLI profile to use for credentials"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "node_pool_size" {
  description = "Number of nodes in the ARM-based node pool"
  type        = number
  default     = 3
}

variable "kubernetes_version" {
  description = "Kubernetes version for the OKE cluster"
  type        = string
  default     = "v1.27.2"
}

variable "availability_domain" {
  description = "The availability domain for the node pool"
  type        = string
  default     = "GrCH:US-ASHBURN-AD-1"
}

variable "node_image_id" {
  description = "The OCID of the image to use for node pool instances (Oracle-Linux-7.9-aarch64)"
  type        = string
  # Find ARM image OCIDs here: https://docs.oracle.com/en-us/iaas/images/
  default     = "ocid1.image.oc1.iad.aaaaaaaafjeywk4m2vd5nyfd3pibt5qvyomsyqjwwk4oel5zdm6g5z6ndbsq"
}
