## Assumptions
- It's an EKS private cluster
- You have access to de EKS cluster
- AWS profiles are set up
- Nodes are on-demand type
- VPC and Subnet ID's are already set (not set in the current code)
- We want to grant access only to specific SG groups (for example we use a VPN to connect to the private cluster, so we use the VPN's sg id)

## Notes
- Ignoring environments in vars to make things easier
- The code is not 100% tested, is an approximation, some values are random, like instance types, sizes, etc