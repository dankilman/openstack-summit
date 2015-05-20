variable "user_name" {
	description = "OpenStack username"
}

variable "key_path" {
	description = "Private key file path"
}

variable "tenant_name" {
	description = "OpenStack tenant"
}

variable "auth_url" {
	description = "OpenStack keystone auth url"
}

variable "password" {
	description = "OpenStack password"
}

variable "region" {
    description = "OpenStack region"
}

variable "mongo_port" {
	default = "27017"
}

variable "mongo_web_port" {
    default = "28017"
}

variable "image_name" {
	deafult = "ubuntu-trusty-1404"
} 

variable "flavor_name" {
	description = "OpenStack vm flavor"
} 






