# Kubernetes Documentation

## Kubernetes Manifests (`k8s/`)

### Core Application Files

#### `namespace.yaml`
Creates the `practice-app` namespace for resource isolation.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: practice-app
```

#### `deployment.yaml`
Main application deployment with health checks and resource limits.

**Key Features:**
- 2 replicas for high availability
- Readiness and liveness probes
- Resource requests and limits
- Full ECR image path

#### `service.yaml`
ClusterIP service exposing the application internally.

**Configuration:**
- Port 80 → Container Port 3000
- Internal cluster access only
- Load balancer integration via ingress

#### `ingress.yaml`
AWS Load Balancer Controller ingress for external access.

**Features:**
- Internet-facing ALB
- HTTP traffic routing
- ALB-specific annotations
- Automatic SSL (future enhancement)

### Advanced Configuration Files

#### `configmaps.yml`
Demonstrates ConfigMap usage for application configuration.

**Contents:**
- Environment variables (NODE_ENV, LOG_LEVEL, etc.)
- Alternative deployment using ConfigMap injection
- Configuration management patterns

#### `service-discovery.yml`
Complete example with advanced features.

**Components:**
- Client pod for testing service discovery
- Enhanced deployment with resource limits
- Secrets management for sensitive data
- Service-to-service communication patterns

#### `advanced-k8s.yml`
Production-ready Kubernetes patterns.

**Features:**
- Horizontal Pod Autoscaler (HPA)
- Network policies for security
- Persistent volume claims
- Init containers and startup probes
- Load testing capabilities

### Environment-Specific Configurations

#### Staging Environment (`k8s/environments/staging/`)
- **Namespace**: `practice-app-staging`
- **Replicas**: 1
- **Resources**: Minimal allocation
- **Ingress**: Internal only

#### Production Environment (`k8s/environments/production/`)
- **Namespace**: `practice-app-prod`
- **Replicas**: 3
- **Resources**: High allocation
- **Ingress**: Full ALB access

## Deployment Strategies

### Quick Start Deployment
```bash
# Deploy core application
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Verify deployment
kubectl get all -n practice-app
kubectl get ingress -n practice-app
```

### Environment-Specific Deployment
```bash
# Staging
kubectl apply -f k8s/environments/staging/

# Production
kubectl apply -f k8s/environments/production/
```

### Advanced Features Deployment
```bash
# With ConfigMaps and Secrets
kubectl apply -f k8s/configmaps.yml
kubectl apply -f k8s/service-discovery.yml

# Production-ready with autoscaling
kubectl apply -f k8s/advanced-k8s.yml
```

## Common Kubernetes Commands

### Resource Management
```bash
# View all resources in namespace
kubectl get all -n practice-app

# Check pod status
kubectl get pods -n practice-app -o wide

# Describe resources
kubectl describe deployment practice-node-app -n practice-app
kubectl describe pod <pod-name> -n practice-app

# Scale deployment
kubectl scale deployment practice-node-app --replicas=3 -n practice-app
```

### Debugging and Logs
```bash
# View pod logs
kubectl logs -f deployment/practice-node-app -n practice-app

# Access application locally
kubectl port-forward service/practice-node-app 3000:80 -n practice-app

# Execute commands in pod
kubectl exec -it <pod-name> -n practice-app -- /bin/bash

# Check events
kubectl get events -n practice-app --sort-by='.lastTimestamp'
```

### Configuration Management
```bash
# View ConfigMaps
kubectl get configmaps -n practice-app
kubectl describe configmap practice-app-config -n practice-app

# View Secrets
kubectl get secrets -n practice-app
kubectl describe secret practice-app-secrets -n practice-app

# Edit resources
kubectl edit deployment practice-node-app -n practice-app
```

### Application Updates
```bash
# Update image
kubectl set image deployment/practice-node-app node-app=new-image:tag -n practice-app

# Rollout status
kubectl rollout status deployment/practice-node-app -n practice-app

# Rollback deployment
kubectl rollout undo deployment/practice-node-app -n practice-app

# Rollout history
kubectl rollout history deployment/practice-node-app -n practice-app
```

## Health Checks and Probes

### Readiness Probe
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
```

### Liveness Probe
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 15
  periodSeconds: 20
  timeoutSeconds: 5
  failureThreshold: 3
```

### Health Endpoint Requirements
The application must implement:
- **GET /health**: Returns 200 OK when healthy
- **Response time**: Under 1 second
- **Headers**: Proper HTTP status codes

## Resource Management

### CPU and Memory Requests
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Resource Sizing Guidelines
- **Development**: 64Mi memory, 50m CPU
- **Staging**: 128Mi memory, 100m CPU
- **Production**: 256Mi memory, 200m CPU

### Horizontal Pod Autoscaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: practice-node-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: practice-node-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Security Configuration

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: practice-app-netpol
spec:
  podSelector:
    matchLabels:
      app: practice-node-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: practice-node-app
    ports:
    - protocol: TCP
      port: 3000
```

### Secrets Management
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: practice-app-secrets
type: Opaque
data:
  DB_PASSWORD: <base64-encoded-password>
  API_KEY: <base64-encoded-api-key>
```

### RBAC Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: practice-app
  name: practice-app-role
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
```

## Monitoring and Observability

### Pod Monitoring
```bash
# Resource usage
kubectl top pods -n practice-app

# Detailed metrics
kubectl describe node <node-name>
```

### Application Monitoring
- **Metrics Server**: Required for HPA and resource monitoring
- **Prometheus**: Optional for advanced monitoring
- **Grafana**: Optional for visualization
- **Jaeger**: Optional for distributed tracing

### Logging Strategy
- **Container Logs**: Collected by CloudWatch
- **Application Logs**: Structured JSON format
- **Audit Logs**: Kubernetes API server logging
- **Access Logs**: Ingress controller logs

## Troubleshooting Kubernetes

### Common Pod Issues

#### ImagePullBackOff
```bash
# Check image existence
kubectl describe pod <pod-name> -n practice-app

# Verify ECR access
aws ecr describe-images --repository-name practice-node-app
```

#### Pending Pods
```bash
# Check resource constraints
kubectl describe pod <pod-name> -n practice-app
kubectl top nodes

# Check events
kubectl get events -n practice-app --sort-by='.lastTimestamp'
```

#### CrashLoopBackOff
```bash
# View pod logs
kubectl logs <pod-name> -n practice-app --previous

# Check resource limits
kubectl describe pod <pod-name> -n practice-app
```

### Service and Ingress Issues

#### Service Not Working
```bash
# Test service connectivity
kubectl run test-pod --image=curlimages/curl -it --rm -- /bin/sh
curl http://practice-node-app.practice-app.svc.cluster.local

# Check service endpoints
kubectl get endpoints practice-node-app -n practice-app
```

#### Ingress Issues
```bash
# Check ingress status
kubectl describe ingress practice-node-app -n practice-app

# Verify ALB controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Advanced Troubleshooting

#### Network Connectivity
```bash
# Test DNS resolution
nslookup kubernetes.default.svc.cluster.local

# Test service connectivity
telnet practice-node-app.practice-app.svc.cluster.local 80
```

#### Resource Analysis
```bash
# Detailed resource usage
kubectl describe node <node-name>

# Cluster capacity
kubectl get nodes -o wide
kubectl top nodes
```

This Kubernetes configuration provides a robust foundation for running containerized applications with proper observability, security, and scalability.
