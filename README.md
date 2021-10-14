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

Specifically in the Demo - we are using the AWS Terraform Provider to deploy Infrastructure into an Amazon Web Services account (More on that below).

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

Lastly - to my point of talking about monitoring credentials for abuse/theft, I have actually included a sample AWS Lambda Function that can take the input of a CloudTrail event, check if the role in use is our Pipeline Credential, and then if source IP Address is not a known IP Address utilized by GitHub Actions (They publish those via their metadata API, see their documentation [here](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners) and the actual API in question [here](https://docs.github.com/en/rest/reference/meta)). Obviouly the detection logic is specific to the setup of the demo architecture, and would also be better for production by periodically copying the IP Addresses to an S3 Bucket, and then having our automation read from that and cache it (Out of scope, unless I manage to get around to it before the talk :smirk: ). You will find the code for that [here](). 

### State/State File

Recapping on the State File - it can (and will based on the demo) contain sensitive information, especially if your template involves secrets as data sources, or other sensitive values (you can see Terraforms own guidance on protecting the state file [here](https://www.terraform.io/docs/language/state/sensitive-data.html)).

Terraform Plans used to accidentally leak/expose sensitive values - but a feature for Terraform was added to mark values as "sensitive" preventing them from appearing in console output for plans/applys - formal announcement [here](https://www.hashicorp.com/blog/terraform-0-14-adds-the-ability-to-redact-sensitive-values-in-console-output). In addition to marking variables/properties at the template level itself sensitive - Provider developers can also do this at the provider schema level (that way the consumer of the Provider doesn't have to worry about it).

That being said - when using self hosted Terraform - absolutely be sure to take advantage of Terraforms [Remote State](https://www.terraform.io/docs/language/state/remote.html) capability - which allows you to store the state in a data store, such as an S3 bucket. If you do, be sure to:
 - apply least privileged access to the bucket
 - Protect the bucket from deletion
 - enable versioning to protect against misconfigurations
 - enable encryption at rest on the bucket (This will be transparent to TF)

### Modules/Extensions Security

As referenced in the talk - Modules/Providers/Extensions (Official terminology varies by tool) are either true code under the hood (in the case of Terraform Providers - Go, or CloudFormation Resource Providers/Custom Resources - any language that can be run in AWS Lambda), or actual code themselves (Things like Pulumi or the AWS Cloud Development Kit which define infrastructure in true, turing complete languages). With that being said - the possibility of using these as a vehicle for disguising malicious code is totally valid. Definetly not something to "gatekeep" over - but worth keeping in mind that the capability exists and could be used by an advanced threat actor/smart red teamer.

Alex Kaskaso wrote an awesome walkthrough of this abusing Terraform via malicious modules - check it out [here](https://alex.kaskaso.li/post/terraform-plan-rce)

This section spoke more to malicious code, and not a template containing a malicous configuration (eg - someone deploying Terraform that creates an external assumable role in AWS for malicious purposes)- that would be covered in part by Static Code Analysis, which is talked about below (and later in the slides).

### Codifying Best Practices - Providing Modules To Your Dev Teams

To not literally rewrite the contents of my slide here, links to all of the "Module" functionalites for each IaC tool that supports them:
 - [CloudFormation Modules](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/modules.html)
 - [Terraform Modules](https://www.terraform.io/docs/language/modules/develop/index.html)
 - [AWS CDK Constructs](https://docs.aws.amazon.com/cdk/latest/guide/constructs.html)
 - [Pulumi Classes via Package Managers](https://www.pulumi.com/blog/creating-and-reusing-cloud-components-using-package-managers/)

 From the security perspective - creating and contributing to IaC modules allow us to:
  1. Get large scale security wins by baking secure design patterns into modules for common application architectures for your business. For example, a 3-tier web app with properly configured AWS Security Groups, network isolation, RDS Backups, WAF, etc, or a microservice backed by API Gateway, AWS Lambda and AWS DynamoDB with properly scoped IAM Access, Authentication, Logging, etc
  2. Take common security systems/services that teams need to use on an individual level and share them to other teams, things like WAFs, Network Firewalls, Bastion Hosts, etc are all great candidates for this.

  When writing modules - be sure to:
  - Version them!
  - Test them!
  - Use them yourself!
  - Be wary of "Bad Abstractions", accidentally closing over useful configuration, and realize litte to no abstraction is often better then a bad one

### Change Control And Management

### Finding Misconfigurations Before Deployment

### Credentials In Code