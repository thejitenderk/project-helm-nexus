#!/bin/bash

##############################################################################
# Harness CD Integration Guide - Shell Script Step
##############################################################################

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║             HARNESS CD - HELM DEPLOYMENT INTEGRATION GUIDE                 ║
╚════════════════════════════════════════════════════════════════════════════╝

SETUP STEPS FOR HARNESS CD PIPELINE:

1. CREATE A NEW SHELL SCRIPT STEP IN HARNESS
   ────────────────────────────────────────────

   Pipeline > Add Stage > Deployment > Add Step > Shell Script

2. CONFIGURE THE SHELL SCRIPT STEP
   ────────────────────────────────

   Step Name: Deploy Helm Chart
   
   Shell Script Content (copy below):
   ────────────────────────────────────
   
   #!/bin/bash
   set -e
   
   # Configuration
   GIT_REPO="https://github.com/thejitenderk/project-helm-nexus"
   GIT_BRANCH="<+pipeline.variables.gitBranch>"
   RELEASE_NAME="<+pipeline.variables.releaseName>"
   NAMESPACE="<+pipeline.variables.namespace>"
   
   # Get script from artifact/repository
   SCRIPT_PATH="/tmp/deploy.sh"
   
   # Make script executable
   chmod +x "$SCRIPT_PATH"
   
   # Run deployment
   bash "$SCRIPT_PATH" "$GIT_REPO" "$GIT_BRANCH" "$RELEASE_NAME" "$NAMESPACE"
   
   ────────────────────────────────────────────

3. ADD PIPELINE VARIABLES
   ───────────────────────

   Go to Pipeline > Variables (or Service/Environment)
   
   Add these variables:
   
   Variable Name: gitBranch
   - Type: String
   - Default: main
   - Allowed Values: main, develop, staging
   
   Variable Name: releaseName
   - Type: String
   - Default: voting-app-release
   
   Variable Name: namespace
   - Type: String
   - Default: harness-ns

4. UPLOAD deploy.sh TO HARNESS
   ───────────────────────────

   Option A: Add to File Store
   - Go to Harness > Account > File Store
   - Upload deploy.sh as a file
   - Reference as: ${fileStore.getAsString("deploy.sh")}
   
   Option B: Add to Git Repository
   - Commit deploy.sh to your repo
   - Reference: /path/to/deploy.sh in your repository
   
   Option C: Inline in Pipeline
   - Copy entire deploy.sh content directly in shell script
   - Paste the complete script

5. CONFIGURE KUBERNETES CONNECTOR
   ──────────────────────────────

   Service > Infrastructure > Set Kubernetes Connector
   - Configure with kubeconfig
   - Ensure proper RBAC permissions for:
     * helm list
     * helm get manifest
     * kubectl apply (dry-run)
     * kubectl get pods

6. ADD INFRASTRUCTURE DETAILS
   ──────────────────────────

   Service > Deployment Specification
   - Connector: Your Kubernetes cluster
   - Namespace: harness-ns
   - Execution Strategy: Rolling/Blue-Green (based on preference)

7. ADVANCED: ENABLE STEADY STATE WAIT
   ──────────────────────────────────

   Environment > Service Configuration > Native Helm Wait Steady State
   - Enable: ✓
   - Workload Type: Deployment
   - Timeout: 10 minutes

8. RUN THE PIPELINE
   ─────────────────

   Manual Execution:
   - Click "Run"
   - Select values for gitBranch, releaseName, namespace
   - Execute

   With Inputs:
   - Git Branch: main
   - Release Name: voting-app-release
   - Namespace: harness-ns

═══════════════════════════════════════════════════════════════════════════════

SHELL SCRIPT STEP - COMPLETE EXAMPLE:

#!/bin/bash
set -e

# Variables from Harness
GIT_REPO="https://github.com/thejitenderk/project-helm-nexus"
GIT_BRANCH="${GIT_BRANCH:-main}"
RELEASE_NAME="${RELEASE_NAME:-voting-app-release}"
NAMESPACE="${NAMESPACE:-harness-ns}"

echo "[Harness] Deploying Helm Chart"
echo "[Harness] Git Repo: $GIT_REPO"
echo "[Harness] Branch: $GIT_BRANCH"
echo "[Harness] Release: $RELEASE_NAME"
echo "[Harness] Namespace: $NAMESPACE"

# Assume deploy.sh is available at this path
DEPLOY_SCRIPT="./deploy.sh"

# Make executable
chmod +x "$DEPLOY_SCRIPT"

# Run deployment
bash "$DEPLOY_SCRIPT" "$GIT_REPO" "$GIT_BRANCH" "$RELEASE_NAME" "$NAMESPACE"

echo "[Harness] Deployment completed!"

═══════════════════════════════════════════════════════════════════════════════

EXPECTED OUTPUT IN HARNESS LOGS:

[INFO] ==========================================
[INFO] Git Clone Step
[INFO] ==========================================
[INFO] Step 0: Cloning Git repository...
[INFO] Repository: https://github.com/thejitenderk/project-helm-nexus
[INFO] Branch:     main
[INFO] Target Dir: helm-chart-repo
[INFO] ✓ Repository cloned successfully to helm-chart-repo
[INFO] ✓ Chart.yaml verified in cloned repository

[INFO] ==========================================
[INFO] Helm Deployment Script
[INFO] ==========================================
[INFO] Step 1: Rendering Helm chart with helm template...
[INFO] ✓ Manifests rendered to manifests-rendered.yaml

[INFO] Step 2: Performing kubectl dry-run (client-side)...
[INFO] ✓ Dry-run completed successfully

[INFO] Step 4: Running helm upgrade (install if not exists)...
[INFO] ✓ Helm upgrade completed

[INFO] Step 6: Checking deployed controllers...
[INFO] Resource Counts:
[INFO]   Deployments:   4
[INFO]   StatefulSets:  0
[INFO]   DaemonSets:    0
[INFO]   Services:      4
[INFO]   ConfigMaps:    4
[INFO]   Secrets:       4

[INFO] Step 7: Pod status in cluster:
NAME                               READY   STATUS    RESTARTS   AGE
result-app-xxxx                    1/1     Running   0          2m
voting-app-xxxx                    1/1     Running   0          2m
voting-postgres-xxxx               1/1     Running   0          2m
voting-redis-xxxx                  1/1     Running   0          2m

[INFO] Deployment Summary
[INFO] ✓ Release deployed: voting-app-release
[INFO] ✓ Namespace: harness-ns
[INFO] ✓ Controllers detected: 4

═══════════════════════════════════════════════════════════════════════════════

TROUBLESHOOTING IN HARNESS:

Issue: "Chart.yaml not found"
→ Ensure deploy.sh is at correct path
→ Check git repo URL is accessible
→ Verify branch name exists

Issue: "kubectl apply failed"
→ Check Kubernetes connector configuration
→ Verify kubeconfig has proper RBAC permissions
→ Ensure namespace exists or --create-namespace is set

Issue: "Deployed Controllers [0]" (steady state not detected)
→ Verify native helm wait is enabled at service level
→ Check harness.io/release-name labels are present
→ Ensure environment has proper infrastructure setup
→ Check delegate logs for parsing errors

Issue: "Git clone failed"
→ Check repository URL is correct
→ Verify branch exists
→ Ensure delegate has network access to GitHub
→ Check for firewall/proxy issues

═══════════════════════════════════════════════════════════════════════════════

BEST PRACTICES:

1. Version Control
   - Keep deploy.sh in Git repository
   - Use semantic versioning for releases

2. Variables Management
   - Use Harness pipeline variables instead of hardcoding
   - Create separate environments (dev, staging, prod)

3. Security
   - Never commit credentials
   - Use Harness secrets for sensitive data
   - Restrict RBAC permissions

4. Monitoring
   - Enable execution logs
   - Set up notifications on success/failure
   - Monitor steady state timeout

5. Rollback Strategy
   - Script provides: helm rollback <release> --namespace=<namespace>
   - Configure automatic rollback on failure
   - Keep release history for quick recovery

═══════════════════════════════════════════════════════════════════════════════

QUICK COMMANDS FOR TESTING:

# Test locally first
./deploy.sh "https://github.com/thejitenderk/project-helm-nexus" "main" "voting-app-release" "harness-ns"

# Verify in Kubernetes
kubectl get deploy -n harness-ns -l harness.io/release-name=voting-app-release
kubectl get pods -n harness-ns
helm list -n harness-ns

# Rollback if needed
helm rollback voting-app-release --namespace=harness-ns

═══════════════════════════════════════════════════════════════════════════════

EOF
