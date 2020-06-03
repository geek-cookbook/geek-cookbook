## Terraform

We _could_ describe the manual gcloud/ssh steps required to deploy a Kubernetes cluster to Google Kubernetes Engine, but using Terraform allows us to abstract ourself from the provider, and focus on just the infrastructure we need built.

The terraform config we produce is theoretically reusabel across AWS, Azure, OpenStack, as well as GCE.

Install terraform locally - on OSX, I used ```brew install terraform```

Confirm it's correctly installed by running ```terraform -v```. My output looks like this:

```
[davidy:~] % terraform -v
Terraform v0.11.8

[davidy:~] %
```

## Google Cloud SDK

I can't remember how I installed gcloud, but I don't think I used homebrew. Run ```curl https://sdk.cloud.google.com | bash``` for a standard install, followed by ```gcloud init``` for the first-time setup.

This works:

```
cat <<-"BREWFILE" > Brewfile
cask 'google-cloud-sdk'
brew 'kubectl'
brew 'terraform'
BREWFILE
brew bundle --verbose
```


### Prepare for terraform

I followed [this guide](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) to setup the following in the "best" way:

Run ```gcloud beta billing accounts list``` to get your billing account

```

export TF_ADMIN=tf-admin-funkypenguin
export TF_CREDS=serviceaccount.json
export TF_VAR_org_id=250566349101
export TF_VAR_billing_account=0156AE-7AE048-1DA888
export TF_VAR_region=australia-southeast1
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}

gcloud projects create ${TF_ADMIN} --set-as-default
gcloud beta billing projects link ${TF_ADMIN} \
  --billing-account ${TF_VAR_billing_account}

  gcloud iam service-accounts create terraform \
    --display-name "Terraform admin account"
  Created service account [terraform].

  gcloud iam service-accounts keys create ${TF_CREDS} \
    --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com
  created key [c0a49832c94aa0e23278165e2d316ee3d5bad438] of type [json] as [serviceaccount.json] for [terraform@funkypenguin-terraform-admin.iam.gserviceaccount.com]

  gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  >   --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  >   --role roles/viewer
  bindings:
  - members:
    - user:googlecloud2018@funkypenguin.co.nz
    role: roles/owner
  - members:
    - serviceAccount:terraform@funkypenguin-terraform-admin.iam.gserviceaccount.com
    role: roles/viewer
  etag: BwV0VGSzYSU=
  version: 1gcloud projects add-iam-policy-binding ${TF_ADMIN} \
>   --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
>   --role roles/viewer
bindings:
- members:
  - user:googlecloud2018@funkypenguin.co.nz
  role: roles/owner
- members:
  - serviceAccount:terraform@funkypenguin-terraform-admin.iam.gserviceaccount.com
  role: roles/viewer
etag: BwV0VGSzYSU=
version: 1

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
>   --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
>   --role roles/storage.admin
bindings:
- members:
  - user:googlecloud2018@funkypenguin.co.nz
  role: roles/owner
- members:
  - serviceAccount:terraform@funkypenguin-terraform-admin.iam.gserviceaccount.com
  role: roles/storage.admin
- members:
  - serviceAccount:terraform@funkypenguin-terraform-admin.iam.gserviceaccount.com
  role: roles/viewer
etag: BwV0VGZwXfM=
version: 1


gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com

## FIXME
Enabled Kubernetes Engine API in the tf-admin project, so that terraform can actually compute versions of the engine available

## FIXME

I had to add compute admin, service admin, and kubernetes engine admin to my org-level account, in order to use gcloud get-cluster-credentilals



gsutil mb -p ${TF_ADMIN} gs://${TF_ADMIN}
Creating gs://funkypenguin-terraform-admin/...
[davidy:~/Documents  remix/kubernetes/terraform] master(+1/-0)* 
[davidy:~/Documents  remix/kubernetes/terraform] master(+1/-0)*  cat > backend.tf <<EOF
heredoc> terraform {
heredoc>  backend "gcs" {
heredoc>    bucket  = "${TF_ADMIN}"
heredoc>    path    = "/terraform.tfstate"
heredoc>    project = "${TF_ADMIN}"
heredoc>  }
heredoc> }
heredoc> EOF
[davidy:~/Documents  remix/kubernetes/terraform] master(+1/-0)*  gsutil versioning set on gs://${TF_ADMIN}
Enabling versioning for gs://funkypenguin-terraform-admin/...
[davidy:~/Documents  remix/kubernetes/terraform] master(+1/-0)*  export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
export GOOGLE_PROJECT=${TF_ADMIN}


```

### Create Service Account

Since it's probably not a great idea to associate your own, master Google Cloud account with your automation process (after all, you can't easily revoke your own credentials if they leak), create a Service Account for terraform under GCE, and grant it the "Compute Admin" role.

Download the resulting JSON, and save it wherever you're saving your code. Remember to protect this .json file like a password, so add it to .gitignore if you're checking your code into git (_and if you're not checking your code into git, what's wrong with you, just do it now!_)

### Setup provider.tf

I setup my provider like this, noting that the project name (which must already be created) came from the output of ```gloud projects list```, and region/zone came from https://cloud.google.com/compute/docs/regions-zones/

```
# Specify the provider (GCP, AWS, Azure)
provider "google" {
credentials = "${file("serviceaccount.json")}"
project = "funkypenguin-mining-pools"
region = "australia-southeast1"
}
```

### Setup compute.tf

Just playing, I setup this:

```
# Create a new instance
resource "google_compute_instance" "ubuntu-xenial" {
   name = "ubuntu-xenial"
   machine_type = "f1-micro"
   zone = "us-west1-a"
   boot_disk {
      initialize_params {
      image = "ubuntu-1604-lts"
   }
}
network_interface {
   network = "default"
   access_config {}
}
service_account {
   scopes = ["userinfo-email", "compute-ro", "storage-ro"]
   }
}
```

### Initialize and plan (it's free)

Run ```terraform init``` to initialize Terraform

Then run ```terrafor plan``` to check that the plan looks good.

### Apply (not necessarily free)

Once your plan (above) is good, run ```terraform apply``` to put it into motion. This is the point where you may start incurring costs.

### Setup kubectl

gcloud container clusters get-credentials $(terraform output cluster_name) --zone $(terraform output cluster_zone) --project $(terraform output project_id)
