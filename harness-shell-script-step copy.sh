#!/bin/bash

##############################################################################
# Harness CD - Shell Script Step for Helm Deployment
# 
# This script is designed to be used directly in a Harness Shell Script step
# Copy the content between the markers and paste into Harness
#
##############################################################################

set -e

# ============================================================================
# PASTE CONTENT BELOW INTO HARNESS SHELL SCRIPT STEP
# ============================================================================

#!/bin/bash
set -e

# Harness Variables (use <+variable.name> syntax in Harness UI)
GIT_REPO="https://github.com/thejitenderk/project-helm-nexus"
GIT_BRANCH="${GIT_BRANCH:-main}"
RELEASE_NAME="${RELEASE_NAME:-voting-app-release}"
NAMESPACE="${NAMESPACE:-harness-ns}"
VALUES_FILE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[HARNESS-INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[HARNESS-WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[HARNESS-ERROR]${NC} $1"
}

# Print environment
log_info "=========================================="
log_info "Harness Helm Deployment"
log_info "=========================================="
log_info "Git Repository: $GIT_REPO"
log_info "Git Branch:     $GIT_BRANCH"
log_info "Release Name:   $RELEASE_NAME"
log_info "Namespace:      $NAMESPACE"
log_info "Working Dir:    $(pwd)"
log_info "=========================================="
echo

# ============================================================================
# STEP 0: Clone Repository
# ============================================================================

CLONE_DIR="helm-chart-repo"

if [ -d "$CLONE_DIR" ]; then
    log_warn "Clone directory exists, removing..."
    rm -rf "$CLONE_DIR"
fi

log_info "Step 0: Cloning repository from $GIT_REPO"
log_info "Executing: git clone --branch $GIT_BRANCH --depth 1 $GIT_REPO $CLONE_DIR"

if ! git clone --branch "$GIT_BRANCH" --depth 1 "$GIT_REPO" "$CLONE_DIR" 2>&1 | grep -E "Cloning|Unpacking"; then
    log_error "Failed to clone repository"
    log_error "Check: URL correctness, branch existence, network access"
    exit 1
fi

log_info "✓ Repository cloned successfully"

# Verify Chart.yaml exists
if [ ! -f "$CLONE_DIR/Chart.yaml" ]; then
    log_error "Chart.yaml not found in cloned repository"
    exit 1
fi

log_info "✓ Chart.yaml verified"
echo

# ============================================================================
# STEP 1: Helm Template
# ============================================================================

log_info "Step 1: Rendering Helm templates"
MANIFEST_FILE="manifests-rendered.yaml"

helm template "$RELEASE_NAME" "$CLONE_DIR" \
    --namespace "$NAMESPACE" \
    > "$MANIFEST_FILE"

if [ ! -s "$MANIFEST_FILE" ]; then
    log_error "Failed to render manifests (empty file)"
    exit 1
fi

log_info "✓ Manifests rendered to $MANIFEST_FILE"
echo

# ============================================================================
# STEP 2: Kubectl Dry-Run
# ============================================================================

log_info "Step 2: Performing kubectl dry-run"
DRY_RUN_FILE="manifests-dry-run.yaml"

kubectl apply --filename="$MANIFEST_FILE" \
    --dry-run=client -o yaml > "$DRY_RUN_FILE" 2>&1 || {
    log_error "Dry-run failed"
    exit 1
}

log_info "✓ Dry-run completed successfully"
echo

# ============================================================================
# STEP 3: Helm Upgrade/Install
# ============================================================================

log_info "Step 3: Running helm upgrade"
log_info "Executing: helm upgrade $RELEASE_NAME $CLONE_DIR --install --namespace $NAMESPACE --create-namespace"

helm upgrade "$RELEASE_NAME" "$CLONE_DIR" \
    --install \
    --namespace "$NAMESPACE" \
    --create-namespace

log_info "✓ Helm upgrade completed"
echo

# ============================================================================
# STEP 4: Verify Deployment
# ============================================================================

log_info "Step 4: Verifying deployment"

# Get release status
log_info "Helm Release Status:"
helm list --filter "^${RELEASE_NAME}$" --namespace="$NAMESPACE" | tail -1

echo

# Get manifest and count resources
MANIFEST_OUTPUT=$(helm get manifest "$RELEASE_NAME" --namespace="$NAMESPACE")
DEPLOYMENT_COUNT=$(echo "$MANIFEST_OUTPUT" | grep -c "^kind: Deployment" || true)
STATEFULSET_COUNT=$(echo "$MANIFEST_OUTPUT" | grep -c "^kind: StatefulSet" || true)
DAEMONSET_COUNT=$(echo "$MANIFEST_OUTPUT" | grep -c "^kind: DaemonSet" || true)
SERVICE_COUNT=$(echo "$MANIFEST_OUTPUT" | grep -c "^kind: Service" || true)
CONFIGMAP_COUNT=$(echo "$MANIFEST_OUTPUT" | grep -c "^kind: ConfigMap" || true)
SECRET_COUNT=$(echo "$MANIFEST_OUTPUT" | grep -c "^kind: Secret" || true)

log_info "Resource Counts:"
echo "  Deployments:   $DEPLOYMENT_COUNT"
echo "  StatefulSets:  $STATEFULSET_COUNT"
echo "  DaemonSets:    $DAEMONSET_COUNT"
echo "  Services:      $SERVICE_COUNT"
echo "  ConfigMaps:    $CONFIGMAP_COUNT"
echo "  Secrets:       $SECRET_COUNT"
echo

# Get pod status
log_info "Pod Status:"
kubectl get pods -n "$NAMESPACE" -l "harness.io/release-name=$RELEASE_NAME" 2>/dev/null || \
kubectl get pods -n "$NAMESPACE" 2>/dev/null || \
log_warn "Could not retrieve pod status"
echo

# ============================================================================
# STEP 5: Summary
# ============================================================================

TOTAL_CONTROLLERS=$(( DEPLOYMENT_COUNT + STATEFULSET_COUNT + DAEMONSET_COUNT ))

log_info "=========================================="
log_info "Deployment Summary"
log_info "=========================================="
log_info "✓ Release deployed: $RELEASE_NAME"
log_info "✓ Namespace: $NAMESPACE"
log_info "✓ Controllers detected: $TOTAL_CONTROLLERS"
log_info "✓ Timestamp: $(date)"
log_info "=========================================="
echo

# ============================================================================
# CLEANUP
# ============================================================================

log_info "Cleaning up cloned repository..."
rm -rf "$CLONE_DIR"
log_info "✓ Cleanup completed"

log_info "Deployment completed successfully!"

# ============================================================================
# END OF HARNESS SHELL SCRIPT STEP CONTENT
# ============================================================================

exit 0
