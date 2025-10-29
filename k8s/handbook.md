eksctl create cluster --name demo-k8s --region ap-southeast-1 --nodegroup-name demo-k8s --nodes 2 --managed
eksctl create cluster -f k8s/personal/minimal-cluster.yaml
aws eks --region ap-southeast-1 update-kubeconfig --name demo-k8s
kubectl apply -f k8s/personal/namespaces.yaml
eksctl delete cluster --region=ap-southeast-1 --name=demo-k8s
aws cloudformation delete-stack --stack-name eksctl-demo-k8s-cluster