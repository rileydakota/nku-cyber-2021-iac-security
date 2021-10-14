# nku-cyber-2021-iac-security
![NKU Cyber Symposium](docs/nkucyber.jpg)

Live Demo Repo and Supporting Content for my NKU Cyber Symposium 2021 talk - The Security Engineers Guide To Infrastructure As Code!

This readme contains the code used for the demo in my talks, as well as anything I couldn't squeeze into the presentation, particularly around other tooling, reads, etc 

It should be noted that this is a "reference architecture" designed to demonstrate some key points relevant to my talk, and only meant for non-production usage in its current state. I will try to cover some of the "missing" asspects (that were mainly kept out for simplicity) below.

Slides Here

Demo Architecture:

![Demo Architecture](docs/labarch_diagram.jpg)

### IaC Tooling

The tooling in question we are using to define our Infrastructure-As-Code is Terraform - a vendor agnostic IaC engine that can be used to manage almost anything with an API. Terraform has a concept of "Providers" - essentually plugins for the platform that tell Terraform how to communicate with an external service so you can manage it using IaC. Terraform has a massive set of official and community maintained providers - check out that list [here](https://registry.terraform.io/browse/providers)

Specicially in the Demo - we are using the AWS Terraform Provider to deploy Infrastructure into an Amazon Web Services account (More on that below).

To the point of other IaC tools - I recommend taking a look at the following:

- [Cloud Development Kit](https://aws.amazon.com/cdk/) 
- [Pulumi](https://www.pulumi.com)
- [AWS CloudFormation](https://aws.amazon.com/cloudformation/)
- [Ansible](https://github.com/ansible/ansible)
- [Kubernetes Manifests](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/) (see also - [Helm Charts](https://artifacthub.io))

### GitOps

### Authentication/Access Control

GIven that our Demo deploys into an Amazon Web Services account - we have to provide credentials privileged enough to deploy infrastructure (or orchestrate whatever we are deploying via Terraform). In the past - this often involved creating an [IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html) with an associated Access Key/Secret Key combo and then providing those credentials to your GitHub Actions Workflows using [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) (For those unfamiliar with AWS - these are static credentials used for programmatic access to your AWS environment). This was the only approach for providing access to CI/CD tooling external to AWS without building something custom (eg - a credential broker tool or using something like CyberArk/HashiCorp Vault). An IAM User might work for small personal projects (even then - I have a strong distaste of them), but it quickly becomes problematic at enterprise scale:
- Depending on your Account/Pipeline model, you may end up with hundreds or thousands of AWS AK/SKs
- All of these need to be periodically rotated - which also requires cooking up automation (Rotate the AK/SK and then update the value) or doing it manually

Our example is making use of the GitHub Actions OAuth capability (At the time of writing - still super new) - which basically allows us to provide temporary credentials to our CI/CD workflow by trusting GitHub (And that particular Repo, or even down to the branch level of this Repo if we so wish) to Federate to our AWS Account using OAuth. Credit to Aidan Steele and the on his super helpful guide on getting this setup [here](https://awsteele.com/blog/2021/09/15/aws-federation-comes-to-github-actions.html) and the AWS GitHub Actions Repo found [here](https://github.com/aws-actions/configure-aws-credentials)

### State/State File

### Modules/Extensions Security

As referenced in the talk - Modules/Providers/Extensions (Official terminology varies by tool) are either true code under the hood (in the case of Terraform Providers - Go, or CloudFormation Resource Providers/Custom Resources - any language that can be run in AWS Lambda), or actual code themselves (Things like Pulumi or the AWS Cloud Development Kit which define infrastructure in true, turing complete languages). With that being said - the possibility of using these as a vehicle for disguising malicious code is totally valid. Definetly not something to "gatekeep" over - but worth keeping in mind that the capability exists and could be used by an advanced threat actor/smart red teamer.

Alex Kaskaso wrote an awesome walkthrough of this abusing Terraform via malicious modules - check it out [here](https://alex.kaskaso.li/post/terraform-plan-rce)

### Codifying Best Practices - Providing Modules To Your Dev Teams

### Change Control And Management

### Finding Misconfigurations Before Deployment

### Credentials In Code