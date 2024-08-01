
# Enabling GPU Slicing on EKS Clusters with Karpenter Autoscaler

This guide provides steps to enable GPU slicing on Amazon Elastic Kubernetes Service (EKS) clusters and leverage the Karpenter Autoscaler for efficient resource management.

## Prerequisites

- **NVIDIA GPUs**: Ensure your EKS nodes are equipped with NVIDIA A100 GPUs.
- **NVIDIA Driver and Toolkit**: Install the appropriate NVIDIA driver and CUDA toolkit.
- **NVIDIA Container Toolkit**: Ensure the NVIDIA Container Toolkit is installed on your nodes.
- **Kubernetes Version**: Ensure your EKS cluster is running Kubernetes version 1.18 or higher.

## Steps to Enable GPU Slicing

### 1. Launch EKS Node with Compatible GPU

When creating an EKS node group, choose an instance type with A100 GPUs (e.g., `p4d`).

### 2. Install NVIDIA Device Plugin for Kubernetes

Deploy the NVIDIA device plugin to allow Kubernetes to discover and manage NVIDIA GPUs.

```bash
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/nvidia-device-plugin.yml
```

### 3. Enable GPU Slicing (MIG Mode)

Configure your GPU to operate in MIG mode by deploying a DaemonSet that configures the GPUs on the nodes.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: mig-manager
spec:
  selector:
    matchLabels:
      name: mig-manager
  template:
    metadata:
      labels:
        name: mig-manager
    spec:
      containers:
      - name: mig-manager
        image: nvcr.io/nvidia/k8s-mig-manager:latest
        securityContext:
          privileged: true
        env:
        - name: MIG_STRATEGY
          value: "single"
```

### 4. Schedule Pods with GPU Slices

Modify your pod specs to request specific GPU slices. For example, to request a single MIG slice (1/7th of an A100 GPU):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  containers:
  - name: cuda-container
    image: nvidia/cuda:11.0-base
    resources:
      limits:
        nvidia.com/gpu: 1
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      value: "MIG-GPU"
```

## Leveraging Karpenter with GPU Slicing

Karpenter is a Kubernetes cluster autoscaler that helps with dynamic provisioning of nodes. Follow these steps to leverage GPU slicing with Karpenter.

### 1. Install Karpenter

```bash
helm repo add karpenter https://charts.karpenter.sh
helm repo update
helm install karpenter karpenter/karpenter --namespace karpenter --create-namespace --version <latest-version>
```

### 2. Configure Karpenter to Support GPU Nodes

Update the Karpenter Provisioner configuration to include GPU instance types.

```yaml
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: "node.kubernetes.io/instance-type"
      operator: In
      values: ["p4d.24xlarge"]
    - key: "kubernetes.io/arch"
      operator: In
      values: ["amd64"]
    - key: "karpenter.k8s.aws/instance-size"
      operator: In
      values: ["large", "xlarge"]
    - key: "karpenter.k8s.aws/instance-type-category"
      operator: In
      values: ["gpu"]
  limits:
    resources:
      cpu: "1000"
      memory: "1000Gi"
      nvidia.com/gpu: "10"
  provider:
    subnetSelector:
      karpenter.sh/discovery: <your-cluster-name>
    securityGroupSelector:
      karpenter.sh/discovery: <your-cluster-name>
```

### 3. Enable Karpenter with GPU Slices

Ensure the Provisioner can recognize and manage GPU slices by configuring the resource requests and limits within the pod specs to match the GPU slicing setup.

## Conclusion

By following these steps, you can enable GPU slicing on your EKS clusters, allowing more efficient use of GPU resources. Integrating Karpenter autoscaler will further enhance resource utilization by dynamically provisioning the required nodes based on workload demands. This setup will help optimize GPU costs while maintaining the performance needed for AI/ML workloads.