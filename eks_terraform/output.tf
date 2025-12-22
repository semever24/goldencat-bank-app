output "cluster_id" {
  value = aws_eks_cluster.sk.id
}

output "node_group_id" {
  value = aws_eks_node_group.sk.id
}

output "vpc_id" {
  value = aws_vpc.sk_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.sk_subnet[*].id
}
