# Kubernetes Manifests & Learning Resources

## 📁 Directory Structure

```
k8s/
├── README.md                    # This file - K8s guide
├── namespace.yaml               # Core namespace
├── deployment.yaml              # Core application deployment
├── service.yaml                 # Core service definition
├── ingress.yaml                # ALB ingress configuration
├── configmaps.yml              # ConfigMap patterns (learning)
├── service-discovery.yml        # Service discovery patterns (learning)
├── advanced-k8s.yml           # Advanced patterns (learning)
├── addons/                     # Cluster addons
│   ├── cluster-autoscaler.yaml   # HPA for cluster scaling
│   └── external-secrets-config.yaml # External Secrets Operator
└── environments/               # Environment-specific configs
    ├── dev/
    ├── staging/
    └── production/
```

## 🎯 Core Deployment Files

### **Essential Files (Production Use)**
- **`namespace.yaml`** - Creates `practice-app` namespace
- **`deployment.yaml`** - Main Node.js application deployment
- **`service.yaml`** - ClusterIP service for internal access
- **`ingress.yaml`** - AWS Load Balancer Controller configuration

**Quick Deploy:**
```bash
kubectl apply -f namespace.yaml \
  -f deployment.yaml \
  -f service.yaml \
  -f ingress.yaml
```

## 📚 Learning & Practice Files

### **ConfigMap Patterns (`configmaps.yml`)**
- Environment-specific configurations
- Application settings management
- Volume mount configurations

**When to use:**
- Environment variables management
- Configuration externalization
- Multi-environment deployments

### **Service Discovery (`service-discovery.yml`)**
- Headless services for pod discovery
- DNS-based service resolution
- Microservice communication patterns

**When to use:**
- Stateful applications
- Database clustering
- Service mesh preparation

### **Advanced Patterns (`advanced-k8s.yml`)**
- **HorizontalPodAutoscaler (HPA)**: Auto-scale based on CPU/memory
- **NetworkPolicy**: Traffic control between pods
- **ResourceQuotas**: Limit namespace resources

**When to use:**
- Production workloads with variable traffic
- Multi-tenant environments
- Security hardening

## 🔧 Addons Configuration

### **Cluster Autoscaler (`addons/cluster-autoscaler.yaml`)**
- Automatically scales EKS node group
- Handles pod-to-node scheduling
- Cost optimization for variable workloads

**Requirements:**
- IAM role with proper permissions
- ASG tags for auto-discovery
- Metrics server deployment

### **External Secrets (`addons/external-secrets-config.yaml`)**
- Syncs AWS SSM to Kubernetes secrets
- Automatic secret rotation
- Secure credential management

**Benefits:**
- No hardcoded secrets in manifests
- Centralized secret management
- Audit trail for secret access

## 🚀 Deployment Strategies

### **Development Environment**
```bash
# Quick dev deployment
kubectl apply -f namespace.yaml -f deployment.yaml -f service.yaml

# Port forward for local testing
kubectl port-forward service/practice-node-app 8080:80 -n practice-app
```

### **Production Deployment**
```bash
# Full production deployment
kubectl apply -f namespace.yaml \
  -f deployment.yaml \
  -f service.yaml \
  -f ingress.yaml \
  -f addons/external-secrets-config.yaml

# Verify deployment
kubectl wait --for=condition=Ready --timeout=300s pod -l app=practice-node-app -n practice-app
```

### **Advanced Features**
```bash
# Enable auto-scaling
kubectl apply -f advanced-k8s.yml

# Enable network policies
kubectl apply -f advanced-k8s.yml

# Monitor HPA
kubectl get hpa -n practice-app
kubectl describe hpa practice-app-hpa -n practice-app
```

## 🔍 Troubleshooting

### **Common Issues**
1. **Pod Pending**: Check resources, image pull, node scheduling
2. **Service Not Accessible**: Verify service selector and port mapping
3. **Ingress Not Working**: Check ALB controller, annotations, security groups

### **Debug Commands**
```bash
# Check pod status
kubectl get pods -n practice-app -o wide

# Describe pod issues
kubectl describe pod <pod-name> -n practice-app

# Check service endpoints
kubectl get endpoints -n practice-app

# Check ingress status
kubectl get ingress -n practice-app

# View logs
kubectl logs -l app=practice-node-app -n practice-app -f

# Check events
kubectl get events -n practice-app --sort-by='.lastTimestamp'
```

## 📋 Best Practices

### **Resource Management**
- Always set resource requests/limits
- Use HPA for production workloads
- Monitor resource usage regularly

### **Security**
- Use NetworkPolicies for multi-tenant clusters
- Enable RBAC for namespace isolation
- Use External Secrets for credential management

### **Monitoring**
- Deploy Prometheus + Grafana stack
- Set up alerting rules
- Log aggregation with Loki/ELK

### **Development Workflow**
1. Use `namespace.yaml` for environment isolation
2. Test with `deployment.yaml` + `service.yaml`
3. Add `ingress.yaml` for external access
4. Gradually adopt advanced patterns from `advanced-k8s.yml`

## 🎯 Learning Path

### **Beginner**
1. Understand core manifests (`namespace.yaml`, `deployment.yaml`)
2. Practice service exposure (`service.yaml`, `ingress.yaml`)
3. Learn basic troubleshooting

### **Intermediate**
1. Master ConfigMaps (`configmaps.yml`)
2. Implement service discovery (`service-discovery.yml`)
3. Set up basic monitoring

### **Advanced**
1. Implement auto-scaling (`advanced-k8s.yml`)
2. Configure network policies
3. Deploy observability stack

## 📖 Additional Resources

- **[Kubernetes Documentation](https://kubernetes.io/docs/)**
- **[AWS EKS User Guide](https://docs.aws.amazon.com/eks/)**
- **[Kubernetes Patterns](https://kubernetespatterns.io/)**
- **[CKA Study Guide](https://github.com/kodekloudhub/certified-kubernetes-administrator)**

---

**Note**: This directory contains both production-ready manifests and learning materials. Start with core files, then gradually adopt advanced patterns as needed.
