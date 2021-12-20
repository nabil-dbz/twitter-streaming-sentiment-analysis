###########################
#### Trraform Variable ####
###########################

variable "access_key" {
    type = string
    sensitive = true
}
variable "secret_key" {
    type = string
    sensitive = true
}

variable "token" {
    type = string
    sensitive = true
}

variable "runtime" {
    type = string
    description = "runtime of the lambda function"
    default = "python3.8"
}
