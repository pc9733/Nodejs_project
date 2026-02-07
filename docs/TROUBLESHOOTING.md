# Troubleshooting Guide

## Common Issues and Solutions

### Infrastructure Issues

#### Terraform State Problems

**Issue: State Lock Error**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Check lock status
terraform force-unlock LOCK_ID

# Or wait for lock to expire (usually 5-10 minutes)
```

**Issue: Resource Already Exists**
```
Error: Error creating IAM role: EntityAlreadyExists
```

**Solution:**
```bash
# Import existing resource
terraform import aws_iam_role.eks_cluster practice-node-app-cluster-role
terraform import aws_eks_cluster.practice practice-node-app

# Or use auto-destroy script
cd infra && ./auto-destroy.sh
```

**Issue: Provider Configuration**
```
Error: Invalid provider configuration
```

**Solution:**
```bash
# Re-initialize providers
terraform init -upgrade

# Check provider versions
terraform version
```

#### AWS Resource Issues

**Issue: EKS Cluster Not Ready**
```bash
# Check cluster status
aws eks describe-cluster --name practice-node-app --query 'cluster.status'

# Check node group status
aws eks describe-nodegroup --cluster-name practice-node-app --nodegroup-name default
```

**Issue: ALB Controller Not Working**
```bash
# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check controller status
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Kubernetes Issues

#### Pod Problems

**Issue: ImagePullBackOff**
```
Status: ImagePullBackOff
```

**Causes & Solutions:**
```bash
# Check image details
kubectl describe pod <pod-name> -n practice-app

# Verify ECR image exists
aws ecr describe-images --repository-name practice-node-app --image-ids imageTag=latest

# Check image pull secrets
kubectl get secret ecr-credentials -n practice-app -o yaml

# Solution: Run GitHub Actions workflow to build/push image
```

**Issue: Pending Pods**
```
Status: Pending
```

**Causes & Solutions:**
```bash
# Check resource constraints
kubectl describe pod <pod-name> -n practice-app
kubectl top nodes

# Check node capacity
kubectl describe nodes

# Common solutions:
# 1. Increase resource requests/limits
# 2. Add more nodes to cluster
# 3. Check taints/tolerations
```

**Issue: CrashLoopBackOff**
```
Status: CrashLoopBackOff
```

**Causes & Solutions:**
```bash
# View pod logs
kubectl logs <pod-name> -n practice-app --previous

# Check application configuration
kubectl describe pod <pod-name> -n practice-app

# Common solutions:
# 1. Fix application bugs
# 2. Correct environment variables
# 3. Fix health check endpoints
# 4. Adjust resource limits
```

#### Service and Ingress Issues

**Issue: Service Not Accessible**
```bash
# Check service endpoints
kubectl get endpoints practice-node-app -n practice-app

# Test service connectivity
kubectl run test-pod --image=curlimages/curl -it --rm -- /bin/sh
curl http://practice-node-app.practice-app.svc.cluster.local

# Check service configuration
kubectl describe service practice-node-app -n practice-app
```

**Issue: Ingress Not Working**
```bash
# Check ingress status
kubectl describe ingress practice-node-app -n practice-app

# Check ALB in AWS console
aws elbv2 describe-load-balancers --names <alb-name>

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Common solutions:
# 1. Verify ALB controller is running
# 2. Check security group rules
# 3. Verify subnet tagging
# 4. Check target health
```

### CI/CD Pipeline Issues

#### GitHub Actions Failures

**Issue: Docker Build Failed**
```
Error: buildx failed with: error
```

**Solutions:**
```bash
# Check Dockerfile syntax
docker build -t test ./node-app

# Verify context path
# Ensure all required files are in node-app/

# Check for large files (>2GB)
du -sh node-app/*
```

**Issue: ECR Push Failed**
```
Error: denied: Your authorization token has expired
```

**Solutions:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify ECR permissions
aws ecr get-authorization-token

# Update GitHub secrets with fresh credentials
```

**Issue: kubectl Commands Failed**
```
Error: error validating data
```

**Solutions:**
```bash
# Check kubeconfig
kubectl config view

# Verify cluster access
aws eks update-kubeconfig --name practice-node-app

# Test cluster connectivity
kubectl get nodes
```

**Issue: Trivy Scan Failed**
```
Error: image scan error
```

**Solutions:**
```bash
# Check if image exists in ECR
aws ecr describe-images --repository-name practice-node-app

# Use correct image tag
# Ensure using 'latest' tag, not commit SHA

# Run Trivy locally for debugging
trivy image <ecr-image-uri>
```

**Issue: Performance Test Failed**
```
Error: Unable to locate package k6
```

**Solutions:**
```bash
# Check k6 installation
k6 version

# Manual installation test
curl -L -o k6.tar.gz "https://github.com/grafana/k6/releases/download/v0.55.0/k6-v0.55.0-linux-amd64.tar.gz"
tar -xzf k6.tar.gz
sudo mv k6-v0.55.0-linux-amd64/k6 /usr/local/bin/
```

### Application Issues

#### Health Check Failures

**Issue: Readiness Probe Failing**
```bash
# Check health endpoint
curl http://localhost:3000/health

# Verify application is running
kubectl logs -f deployment/practice-node-app -n practice-app

# Check probe configuration
kubectl describe deployment practice-node-app -n practice-app
```

**Issue: Application Not Responding**
```bash
# Check application logs
kubectl logs -f deployment/practice-node-app -n practice-app

# Port forward for local testing
kubectl port-forward service/practice-node-app 3000:80 -n practice-app

# Test application locally
curl http://localhost:3000/health
```

### Network Issues

#### Connectivity Problems

**Issue: Cannot Access ALB**
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names <alb-name>

# Check target groups
aws elbv2 describe-target-groups --load-balancer-arn <alb-arn>

# Test ALB endpoint
curl -I http://<alb-dns-name>/health

# Common solutions:
# 1. Check security group inbound rules
# 2. Verify target health
# 3. Check listener configuration
# 4. Verify subnet configuration
```

**Issue: DNS Resolution Problems**
```bash
# Test DNS resolution
nslookup kubernetes.default.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Restart CoreDNS if needed
kubectl rollout restart deployment/coredns -n kube-system
```

### Performance Issues

#### Slow Deployment

**Issue: Rollout Timeout**
```
error: deployment "practice-node-app" exceeded its progress deadline
```

**Solutions:**
```bash
# Check pod status
kubectl get pods -n practice-app -l app=practice-node-app

# Increase timeout
kubectl rollout status deployment/practice-node-app -n practice-app --timeout=900s

# Check resource constraints
kubectl describe pod <pod-name> -n practice-app

# Common solutions:
# 1. Increase resource limits
# 2. Optimize image size
# 3. Check network bandwidth
# 4. Verify registry performance
```

#### High Resource Usage

**Issue: High CPU/Memory Usage**
```bash
# Check resource usage
kubectl top pods -n practice-app
kubectl top nodes

# Describe resource usage
kubectl describe node <node-name>

# Solutions:
# 1. Set appropriate resource limits
# 2. Implement HPA
# 3. Optimize application code
# 4. Scale up cluster
```

## Debugging Commands

### Terraform Debugging
```bash
# Validate configuration
terraform validate

# Format configuration
terraform fmt

# Check state
terraform state list

# Show resource details
terraform state show aws_eks_cluster.practice

# Import existing resource
terraform import aws_iam_role.eks_cluster practice-node-app-cluster-role
```

### Kubernetes Debugging
```bash
# Cluster information
kubectl cluster-info
kubectl get nodes -o wide

# Resource status
kubectl get all -n practice-app
kubectl get events -n practice-app --sort-by='.lastTimestamp'

# Detailed information
kubectl describe deployment practice-node-app -n practice-app
kubectl describe pod <pod-name> -n practice-app

# Logs and debugging
kubectl logs -f deployment/practice-node-app -n practice-app
kubectl exec -it <pod-name> -n practice-app -- /bin/bash

# Network debugging
kubectl run test-pod --image=curlimages/curl -it --rm -- /bin/sh
telnet practice-node-app.practice-app.svc.cluster.local 80
```

### Application Debugging
```bash
# Port forward for local access
kubectl port-forward service/practice-node-app 3000:80 -n practice-app

# Copy files from pod
kubectl cp <pod-name>:/app/logs ./logs -n practice-app

# Execute commands in pod
kubectl exec <pod-name> -n practice-app -- env | grep NODE
```

## Recovery Procedures

### Complete Infrastructure Recovery
```bash
# 1. Clean up existing resources
cd infra && ./auto-destroy.sh

# 2. Remove state files (if needed)
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

# 3. Re-initialize backend + recreate environment
# (choose the script for your environment)
./setup-dev.sh        # or ./setup-prod.sh
./create-dev.sh       # or ./create-prod.sh
```

### Application Recovery
```bash
# 1. Scale down to zero
kubectl scale deployment practice-node-app --replicas=0 -n practice-app

# 2. Clear problematic pods
kubectl delete pods -l app=practice-node-app -n practice-app

# 3. Scale back up
kubectl scale deployment practice-node-app --replicas=2 -n practice-app

# 4. Verify deployment
kubectl rollout status deployment/practice-node-app -n practice-app
```

### Emergency Rollback
```bash
# Quick rollback to previous version
kubectl rollout undo deployment/practice-node-app -n practice-app

# Rollback to specific revision
kubectl rollout undo deployment/practice-node-app --to-revision=2 -n practice-app

# Force rollback if stuck
kubectl patch deployment practice-node-app -n practice-app -p '{"spec":{"rollbackTo":{"revision":2}}}'
```

## Monitoring and Alerting

### Key Metrics to Monitor
- **Pod Status**: Running vs pending/failed pods
- **Resource Usage**: CPU, memory, storage
- **Response Times**: Application response latency
- **Error Rates**: HTTP 5xx and application errors
- **ALB Health**: Target health check status

### Alert Thresholds
- **Pod Restart Rate**: > 5 restarts/minute
- **CPU Usage**: > 80% sustained
- **Memory Usage**: > 85% sustained
- **Response Time**: P95 > 1 second
- **Error Rate**: > 5% of requests

### Log Analysis
```bash
# Application logs
kubectl logs -f deployment/practice-node-app -n practice-app | grep ERROR

# System events
kubectl get events -n practice-app --field-selector type=Warning

# ALB access logs (via CloudWatch)
aws logs get-log-events --log-group-name /aws/elb/<alb-name>
```

## Prevention Strategies

### Infrastructure
- Use `./auto-destroy.sh` for safe cleanup
- Enable Terraform state locking
- Implement proper IAM role separation
- Use remote state backend

### Kubernetes
- Set appropriate resource limits
- Implement health checks
- Use network policies
- Enable pod disruption budgets

### CI/CD
- Test in staging before production
- Use canary deployments for critical changes
- Implement proper rollback procedures
- Monitor pipeline performance

### Application
- Implement proper logging
- Use structured log formats
- Add health check endpoints
- Implement graceful shutdown

This troubleshooting guide covers the most common issues and provides systematic approaches to diagnose and resolve problems in the Node.js EKS deployment pipeline.
