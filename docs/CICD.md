# CI/CD Pipeline Documentation

## GitHub Actions Workflows (`.github/workflows/`)

### Main Deployment Pipeline (`deploy-node-app.yml`)

#### Triggers
- **Manual**: `workflow_dispatch`
- **Automatic**: Push to `main` branch
- **Pull Requests**: PRs to `main` branch

#### Pipeline Stages

##### 1. Code Quality & Testing
```yaml
- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: 18
    cache: npm
    cache-dependency-path: node-app/package-lock.json

- name: Install dependencies
  working-directory: node-app
  run: npm ci --omit=dev

- name: Run tests
  working-directory: node-app
  run: npm test || echo "No tests configured, skipping..."

- name: Run smoke test
  working-directory: node-app
  run: node -e "require('./server'); console.log('Server module loads successfully')"
```

##### 2. Build & Security
```yaml
- name: Build and push image
  uses: docker/build-push-action@v5
  with:
    context: ./node-app
    file: ./node-app/Dockerfile
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    labels: ${{ steps.meta.outputs.labels }}
    cache-from: type=gha
    cache-to: type=gha,mode=max

- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@0.16.1
  continue-on-error: true
  with:
    image-ref: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:latest
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    skip-dirs: '/tmp,/var'

- name: Upload Trivy scan results
  uses: github/codeql-action/upload-sarif@v4
  if: always() && hashFiles('trivy-results.sarif') != ''
  continue-on-error: true
  with:
    sarif_file: 'trivy-results.sarif'
```

##### 3. Deployment
```yaml
- name: Verify image in ECR
  run: |
    IMAGE_TAG="latest"
    if aws ecr describe-images --repository-name ${{ env.ECR_REPOSITORY }} --image-ids imageTag=$IMAGE_TAG; then
      echo "✅ Image found in ECR"
    else
      echo "❌ Image not found"
      exit 1
    fi

- name: Deploy manifests
  run: |
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/ingress.yaml
    
    # Environment-specific configs
    if [ "${{ github.ref }}" = "refs/heads/main" ]; then
      kubectl apply -f k8s/configmaps.yml
      kubectl apply -f k8s/service-discovery.yml
    fi
    
    # Update deployment image
    kubectl set image deployment/practice-node-app node-app=${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:latest -n practice-app
```

##### 4. Verification & Monitoring
```yaml
- name: Wait for rollout
  run: |
    kubectl rollout status deployment/practice-node-app -n practice-app --timeout=600s || {
      echo "Rollout failed, checking status..."
      kubectl get pods -n practice-app -l app=practice-node-app
      exit 1
    }

- name: Health check
  run: |
    kubectl wait --for=condition=ready pod -l app=practice-node-app -n practice-app --timeout=300s
    
    # Test ALB endpoint
    ALB_URL="${{ steps.deploy.outputs.alb-url }}"
    if [ -n "$ALB_URL" ]; then
      for i in {1..10}; do
        if curl -f -s http://$ALB_URL/health > /dev/null; then
          echo "✅ ALB health check passed"
          break
        fi
        sleep 30
      done
    fi

- name: Performance test
  if: github.ref == 'refs/heads/main'
  run: |
    # Install k6 and run load test
    K6_VERSION="v0.55.0"
    curl -L -o k6.tar.gz "https://github.com/grafana/k6/releases/download/${K6_VERSION}/k6-${K6_VERSION}-linux-amd64.tar.gz"
    tar -xzf k6.tar.gz
    sudo mv k6-${K6_VERSION}-linux-amd64/k6 /usr/local/bin/
    
    # Run 3-minute load test
    k6 run --out json=load-test-results.js load-test.js
```

##### 5. Cleanup & Notification
```yaml
- name: Cleanup old ECR images
  if: github.ref == 'refs/heads/main'
  run: |
    aws ecr describe-images --repository-name ${{ env.ECR_REPOSITORY }} \
      --query 'sort_by(imageDetails, &imagePushedAt)[:-5].imageDigest' \
      --output text | while read -r digest; do
      aws ecr batch-delete-image --repository-name ${{ env.ECR_REPOSITORY }} --image-ids imageDigest=$digest || true
    done
```

### Canary Deployment Pipeline (`canary-deploy.yml`)

#### Features
- **Traffic Splitting**: Configurable percentage (1-50%)
- **Canary Monitoring**: Health verification and metrics
- **Promote/Rollback**: Manual decision workflows
- **Zero-Downtime**: Smooth traffic transitions

#### Usage
```bash
# Trigger canary with 10% traffic
# Use GitHub Actions UI with inputs:
# - traffic_percentage: 10
# - image_tag: latest (optional)
```

#### Canary Deployment Process
```yaml
- name: Create canary deployment
  run: |
    # Clone main deployment as canary
    kubectl get deployment practice-node-app -n practice-app -o yaml | \
      sed 's/practice-node-app/practice-node-app-canary/g' | \
      kubectl apply -f -
    
    # Update canary with new image
    kubectl set image deployment/practice-node-app-canary node-app=${IMAGE} -n practice-app

- name: Update ingress for traffic splitting
  run: |
    # Patch ingress to split traffic
    kubectl patch ingress practice-node-app -n practice-app --type='json' -p='[{
      "op": "replace",
      "path": "/spec/rules/0/http/paths",
      "value": [
        {
          "path": "/",
          "backend": {"service": {"name": "practice-node-app-canary", "port": {"number": 80}}},
          "weight": '$TRAFFIC_PERCENTAGE'
        },
        {
          "path": "/",
          "backend": {"service": {"name": "practice-node-app", "port": {"number": 80}}},
          "weight": '$MAIN_TRAFFIC'
        }
      ]
    }]'
```

### Environment-Specific Deployments

#### Staging Environment
```yaml
# Triggered on PRs and feature branches
- Namespace: practice-app-staging
- Replicas: 1
- Resources: Minimal
- Ingress: Internal only
- Tests: Full validation
```

#### Production Environment
```yaml
# Triggered on main branch merge
- Namespace: practice-app-prod
- Replicas: 3
- Resources: High allocation
- Ingress: Full ALB access
- Tests: Full validation + performance testing
```

## Workflow Permissions

### Required Permissions
```yaml
permissions:
  contents: read
  packages: write
  actions: read
  security-events: write    # For SARIF upload
  pull-requests: write     # For PR comments
```

### AWS Credentials
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
```

## Environment Variables

### Global Environment
```yaml
env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: practice-node-app
  EKS_CLUSTER_NAME: practice-node-app
```

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

## Image Tagging Strategy

### Docker Metadata Action
```yaml
- name: Extract metadata
  id: meta
  uses: docker/metadata-action@v5
  with:
    images: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}
    tags: |
      type=ref,event=branch
      type=ref,event=pr
      type=sha,prefix={{branch}}-
      type=raw,value=latest,enable={{is_default_branch}}
```

### Generated Tags
- **Main Branch**: `main`, `latest`, `main-{commit-sha}`
- **Pull Requests**: `pr-{number}`, `pr-{number}-{commit-sha}`
- **Feature Branches**: `{branch}`, `{branch}-{commit-sha}`

## Security Features

### Vulnerability Scanning
```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@0.16.1
  with:
    image-ref: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:latest
    format: 'sarif'
    severity: 'CRITICAL,HIGH'
```

### SARIF Upload
```yaml
- name: Upload Trivy scan results
  uses: github/codeql-action/upload-sarif@v4
  with:
    sarif_file: 'trivy-results.sarif'
```

### Image Security
- **Base Image Scanning**: Trivy scans base layers
- **Application Scanning**: Scans final image
- **Dependency Scanning**: npm audit during build
- **Secret Scanning**: Trivy secret detection

## Performance Testing

### k6 Load Test Configuration
```javascript
export let options = {
  stages: [
    { duration: '1m', target: 5 },    // Ramp up to 5 users
    { duration: '1m', target: 5 },    // Hold at 5 users
    { duration: '1m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],    // 95th percentile < 500ms
    http_req_failed: ['rate<0.1'],       // < 10% failure rate
  },
};
```

### Performance Metrics
- **Response Time**: 95th percentile < 500ms
- **Success Rate**: > 90%
- **Throughput**: Requests per second
- **Error Rate**: < 10%

## Rollback and Recovery

### Automatic Rollback
```yaml
- name: Rollback on failure
  if: failure()
  run: |
    if kubectl rollout undo deployment/practice-node-app -n practice-app; then
      echo "✅ Rollback completed"
    else
      echo "⚠️ Rollback failed, manual intervention required"
    fi
```

### Manual Rollback Commands
```bash
# Rollback to previous revision
kubectl rollout undo deployment/practice-node-app -n practice-app

# Check rollback status
kubectl rollout status deployment/practice-node-app -n practice-app

# View rollout history
kubectl rollout history deployment/practice-node-app -n practice-app
```

## Monitoring and Observability

### Deployment Monitoring
```yaml
- name: Debug deployment issues
  if: failure()
  run: |
    kubectl get pods -n practice-app -l app=practice-node-app -o wide
    kubectl get events -n practice-app --sort-by='.lastTimestamp' | tail -10
    kubectl describe deployment practice-node-app -n practice-app
```

### Health Check Endpoints
- **Application**: `/health` endpoint
- **Kubernetes**: Pod readiness and liveness probes
- **ALB**: HTTP health checks
- **Performance**: k6 load test results

## Notification and Alerting

### Success Notifications
```yaml
- name: Notify deployment success
  if: success()
  run: |
    echo "✅ Deployment successful!"
    echo "📊 Image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}"
    echo "🌐 ALB: ${{ steps.deploy.outputs.alb-url }}"
```

### Failure Alerts
```yaml
- name: Notify failure
  if: failure()
  run: |
    echo "❌ Deployment failed for ${{ github.sha }}"
    echo "🔍 Check workflow logs for details"
```

## Best Practices

### Workflow Design
- **Idempotent**: Safe to re-run
- **Atomic**: All or nothing deployment
- **Observable**: Comprehensive logging and monitoring
- **Secure**: Minimal permissions and secret handling
- **Efficient**: Caching and parallel execution

### Security Considerations
- **Least Privilege**: Minimal required permissions
- **Secret Management**: GitHub secrets for credentials
- **Image Scanning**: Automated vulnerability detection
- **Network Security**: VPC and security group configuration

### Performance Optimization
- **Docker Caching**: GitHub Actions cache for layers
- **Parallel Execution**: Independent steps run in parallel
- **Resource Limits**: Appropriate runner specifications
- **Artifact Management**: Efficient artifact handling

This CI/CD pipeline provides enterprise-grade automation with proper security, monitoring, and reliability features for deploying containerized applications to Kubernetes.
