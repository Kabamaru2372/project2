# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
# Function to print colored output
print_color() {
    echo -e "${2}${1}${NC}"
}
# Function to validate cluster name
validate_cluster_name() {
    local name=$1
    if [[ ! $name =~ ^[a-z0-9-]+$ ]] || [[ ${#name} -gt 30 ]]; then
        print_color "Error: Cluster name must contain only lowercase letters, numbers, hyphens and be under 30 characters." "$RED"
        return 1
    fi
    return 0
}
# Function to validate region
validate_region() {
    local region=$1
    local available_regions=()
    # Try to get the list of regions from AWS CLI
    if available_regions_text=$(aws ec2 describe-regions --all-regions --query 'Regions[].RegionName' --output text 2>/dev/null); then
        # Read the text output into an array
        IFS=$'\t' read -r -a available_regions <<< "$available_regions_text"
    else
        # Fallback to a static list if AWS CLI fails
        available_regions=(
            us-east-1 us-east-2 us-west-1 us-west-2
            af-south-1
            ap-east-1
            ap-south-1 ap-south-2
            ap-southeast-1 ap-southeast-2 ap-southeast-3
            ap-northeast-1 ap-northeast-2 ap-northeast-3
            ca-central-1
            eu-central-1 eu-central-2
            eu-west-1 eu-west-2 eu-west-3
            eu-north-1
            eu-south-1 eu-south-2
            me-south-1 me-central-1
            sa-east-1
        )
    fi
    for available_region in "${available_regions[@]}"; do
        if [[ "$region" == "$available_region" ]]; then
            return 0
        fi
    done
    print_color "Error: Invalid AWS region: $region" "$RED"
    print_color "Available regions: ${available_regions[*]}" "$YELLOW"
    return 1
}
# Function to create cluster
create_cluster() {
    local cluster_name=$1
    local region=$2
    print_color "Starting cluster creation process..." "$BLUE"
    print_color "Cluster Name: $cluster_name" "$YELLOW"
    print_color "Region: $region" "$YELLOW"
    echo
    # Step 1: Create EKS cluster
    print_color "Step 1: Creating EKS cluster..." "$BLUE"
    eksctl create cluster \
        --name $cluster_name \
        --region $region \
        --nodegroup-name ${cluster_name}-workers \
        --node-type t3.medium \
        --max-pods-per-node 100 \
        --nodes 5 \
        --verbose 4
    if [ $? -ne 0 ]; then
        print_color "Error: Failed to create EKS cluster" "$RED"
        return 1
    fi
    # Step 2: Enable OIDC provider
    print_color "Step 2: Enabling OIDC provider for IAM roles..." "$BLUE"
    eksctl utils associate-iam-oidc-provider \
        --region $region \
        --cluster $cluster_name \
        --approve
    if [ $? -ne 0 ]; then
        print_color "Error: Failed to enable OIDC provider" "$RED"
        return 1
    fi
    # Step 3: Create IAM service account for EBS CSI driver
    print_color "Step 3: Creating IAM service account for EBS CSI driver..." "$BLUE"
    eksctl create iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster $cluster_name \
        --region $region \
        --role-name AmazonEKS_EBS_CSI_DriverRole_${cluster_name} \
        --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
        --approve
    if [ $? -ne 0 ]; then
        print_color "Error: Failed to create IAM service account" "$RED"
        return 1
    fi
    # Step 4: Get AWS account ID and install EBS CSI driver
    print_color "Step 4: Installing EBS CSI driver..." "$BLUE"
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_color "AWS Account ID: $AWS_ACCOUNT_ID" "$YELLOW"
    eksctl create addon \
        --name aws-ebs-csi-driver \
        --cluster $cluster_name \
        --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole_${cluster_name} \
        --region $region \
        --force
    if [ $? -ne 0 ]; then
        print_color "Error: Failed to install EBS CSI driver" "$RED"
        return 1
    fi
    # Wait for EBS CSI driver to be ready
    print_color "Waiting for EBS CSI driver to be ready..." "$YELLOW"
    kubectl wait --for=condition=ready pod -l app=ebs-csi-controller -n kube-system --timeout=300s
    print_color "Cluster creation completed successfully!" "$GREEN"
    print_color "You can access your application using the EXTERNAL-IP from the service above." "$GREEN"
}

# Function to check cluster status
check_cluster() {
    local cluster_name=$1
    local region=$2
    print_color "Checking cluster status..." "$BLUE"
    # Check if cluster exists
    if aws eks describe-cluster --name $cluster_name --region $region &>/dev/null; then
        print_color "Cluster '$cluster_name' exists in region '$region'" "$GREEN"
        # Update kubeconfig
        aws eks update-kubeconfig --name $cluster_name --region $region
        # Get cluster info
        echo
        kubectl cluster-info
        echo
        kubectl get nodes
        echo
        kubectl get all -A | grep -v kube-system
    else
        print_color "Cluster '$cluster_name' does not exist in region '$region'" "$RED"
    fi
}
# Main script
main() {
    print_color "=== EKS Cluster Management Script ===" "$BLUE"
    echo
    # Get action from user
    PS3="Select an action: "
    options=("Create Cluster" "Check Cluster Status" "Quit")
    select opt in "${options[@]}"; do
        case $opt in
            "Create Cluster")
                echo
                read -p "Enter cluster name: " cluster_name
                read -p "Enter AWS region (default: us-east-1): " region
                region=${region:-us-east-1}
                if validate_cluster_name "$cluster_name" && validate_region "$region"; then
                    create_cluster "$cluster_name" "$region"
                fi
                break
                ;;
            "Check Cluster Status")
                echo
                read -p "Enter cluster name: " cluster_name
                read -p "Enter AWS region (default: us-east-1): " region
                region=${region:-us-east-1}
                if validate_cluster_name "$cluster_name" && validate_region "$region"; then
                    check_cluster "$cluster_name" "$region"
                fi
                break
                ;;
            "Quit")
                print_color "Goodbye!" "$GREEN"
                exit 0
                ;;
            *)
                print_color "Invalid option. Please try again." "$RED"
                ;;
        esac
    done
}
# Check dependencies
check_dependencies() {
    local deps=("eksctl" "aws" "kubectl")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            print_color "Error: $dep is not installed or not in PATH" "$RED"
            exit 1
        fi
    done
}
# Run main function
check_dependencies
main