module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.20.0"

  cluster_name                    = module.eks.cluster_name
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role      = false
  iam_role_arn         = module.eks.eks_managed_node_groups["eks-main"].iam_role_arn
  irsa_use_name_prefix = false
}

# Helm release
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.37.0"

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
}

# Kubernetes manifest
resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
      annotations:
        kubernetes.io/description: "General purpose NodePool for generic workloads"
    spec:
      template:
        spec:
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["t", "m"]
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["2"]
          nodeClassRef:
            apiVersion: karpenter.k8s.aws/v1beta1
            kind: EC2NodeClass
            name: bottlerocket
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_ec2nodeclass" {
  yaml_body = <<-YAML
   apiVersion: karpenter.k8s.aws/v1beta1
  kind: EC2NodeClass
  metadata:
    name: bottlerocket
    annotations:
      kubernetes.io/description: "EC2NodeClass for running Bottlerocket nodes"
  spec:
    amiFamily: Bottlerocket
    role: "KarpenterNodeRole-ticketgo-dev"
    subnetSelectorTerms:
      - tags:
          karpenter.sh/discovery: "ticketgo-dev"
    securityGroupSelectorTerms:
      - tags:
          karpenter.sh/discovery: "ticketgo-dev"
    blockDeviceMappings:
      - deviceName: /dev/xvda
        ebs:
          volumeType: gp3
          volumeSize: 4Gi
          deleteOnTermination: true
      # Bottlerocket data volume
      - deviceName: /dev/xvdb
        ebs:
          volumeType: gp3
          volumeSize: 20Gi # replace with your required disk size
          deleteOnTermination: true       
  YAML
}
