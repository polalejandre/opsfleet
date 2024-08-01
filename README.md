## Assumptions
- It's an EKS private cluster
- You have access to the EKS cluster network (using a VPN for example)
- AWS profiles are set up
- Nodes are on-demand type
- VPC and Subnet ID's are already set (not set in the current code)
- We want to grant access only to specific SG groups

## Notes
- Ignoring environments in vars to make things easier
- The code is not 100% tested, is an approximation, some values are random, like instance types, sizes, etc
- Explanation of pod deployment doesn't consider any automation or methodology to deploy into the cluster

## Usage

To use this Terraform repository, follow these steps:

1. Clone the repository to your local machine:

    ```bash
    git clone https://github.com/pol/opsfleet.git
    ```

2. Change into the repository directory:

    ```bash
    cd opsfleet
    ```

3. Update the necessary variables in the `terraform.tfvars` file to match your desired configuration.

4. Initialize the Terraform workspace:

    ```bash
    terraform init
    ```

5. Review the planned changes:

    ```bash
    terraform plan
    ```

6. Apply the changes to create the EKS private cluster:

    ```bash
    terraform apply
    ```

7. After successfully applying the changes, you can deploy pods or deployments on either x86 or Graviton instances inside the cluster. Here's an example of how to deploy a pod:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: my-pod
      namespace: my-namespace
    spec:
      containers:
         - name: my-container
            image: nginx
    ```

    Save the above YAML code in a file, for example `my-pod.yaml`. Assuming you've already set up the kubectl access to the cluster, apply the pod:

    ```bash
    kubectl apply -f my-pod.yaml
    ```

    The pod will be scheduled and run on either an x86 or Graviton instance based on the configuration of the cluster.

Please note that the code provided is an approximation and may require further customization based on your specific requirements.
