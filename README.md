# Kubernetes cluster
This is a [terraform](http://terraform.io/) configuration to setup a simple
Kubernetes cluster on [DigitalOcean](https://www.digitalocean.com).

# It should not be used for production.
# It should not be used for production.
# It should not be used for production.

## This is a work in progress
It's just an example about how to use Terraform to describe and apply
an infrastructure on DigitalOcean.

## How to use it
Terraform can be downloaded [here](https://www.terraform.io/downloads.html).

Let's start creating the ssh key to be used to access the servers:
```
ssh-keygen -f secret/id_rsa
```

To initialise the project downloading required provider run:
```
terraform init
```

Create a new DigitalOcean API Token [here](https://cloud.digitalocean.com/settings/api/tokens).

And finally to apply the infrastructure:
```
terraform apply
```

## I'm too lazy
If you don't wanna type the token on every apply, it's fine. Just rename
the file `terraform.tfvars.dist` to `terraform.tfvars` and configure the
token in there.
