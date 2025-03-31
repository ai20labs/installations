#!/bin/bash

# Configuration - Set these variables
RAPID_DEMO_VERSION="1.3.11"
RAPID_DEMO_UI_VERSION="1.3.3"
CHROMA_VERSION="0.6.3"
OLLAMA_VERSION="latest"
DEFAULT_MODEL="gemma3:1b"
EMBED_MODEL_NAME="nomic-embed-text"
# Parse command line arguments
ACTION="install"
MODEL_NAME="$DEFAULT_MODEL"

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --help                 Show this help message"
    echo "  --clean                Clean install (remove existing containers, networks, volumes)"
    echo "  --install              Install the application (default)"
    echo "  --restart              Restart the application"
    echo "  --stop                 Stop the application"
    echo "  --model=MODEL_NAME     Specify the model name (default: gemma3:1b)"
    exit 1
}

for arg in "$@"
do
    case $arg in
        --help)
            print_usage
            ;;
        --clean)
            ACTION="clean"
            ;;
        --install)
            ACTION="install"
            ;;
        --restart)
            ACTION="restart"
            ;;
        --stop)
            ACTION="stop"
            ;;
        --model=*)
            MODEL_NAME="${arg#*=}"
            ;;
        *)
            echo "Unknown option: $arg"
            print_usage
            ;;
    esac
done

# Define constants
NETWORK_NAME="rapid-demo-network"
OLLAMA_VOLUME="ollama"
CHROMA_VOLUME="chroma-data"
BACKEND_CACHE="backend_cache"

# Function to check if Docker is installed and running
check_docker() {
    echo "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed."
        echo "Please install Docker Desktop from:"
        echo "  - Mac: https://docs.docker.com/desktop/setup/install/mac-install/"
        echo "  - Windows: https://docs.docker.com/desktop/setup/install/windows-install/"
        echo "  - Linux: https://docs.docker.com/desktop/setup/install/linux-install/"
        exit 1
    fi

    echo "Docker is installed. Checking if Docker daemon is running..."
    if ! docker info &> /dev/null; then
        echo "Error: Docker daemon is not running."
        echo "Please start Docker Desktop and try again."
        exit 1
    fi

    echo "✅ Docker is installed and running."
}

# Function to stop containers
stop_containers() {
    echo "Stopping containers..."
    docker stop rapid-demo-ui rapid-demo chromadb ollama 2>/dev/null || true
    echo "✅ Containers stopped."
}

# Function to remove containers
remove_containers() {
    echo "Removing containers..."
    docker rm -f rapid-demo-ui rapid-demo chromadb ollama 2>/dev/null || true
    echo "✅ Containers removed."
}

# Function to create network
create_network() {
    echo "Creating network..."
    docker network inspect $NETWORK_NAME &> /dev/null || docker network create -d bridge $NETWORK_NAME
    echo "✅ Network created or already exists."
}

# Function to clean everything
clean_install() {
    echo "Performing clean installation..."

    # Stop and remove containers
    stop_containers
    remove_containers

    # Remove volumes
    echo "Removing volumes..."
    docker volume rm $OLLAMA_VOLUME $CHROMA_VOLUME $BACKEND_CACHE 2>/dev/null || true
    echo "✅ Volumes removed."

    # Remove network
    echo "Removing network..."
    docker network rm $NETWORK_NAME 2>/dev/null || true
    echo "✅ Network removed."

    # Prune unused images
    echo "Pruning unused images..."
    docker image prune -f
    echo "✅ Unused images pruned."

    echo "Clean installation preparation complete."
}

# Function to install components
install_components() {
    echo "Installing WinGov AI components..."

    # Pull images
    echo "Pulling Docker images..."
    docker pull ratish11/rapid-demo:$RAPID_DEMO_VERSION || { echo "Error: Failed to pull Rapid Demo image"; exit 1; }
    docker pull ratish11/rapid-demo-ui:$RAPID_DEMO_UI_VERSION || { echo "Error: Failed to pull Rapid Demo UI image"; exit 1; }
    docker pull chromadb/chroma:$CHROMA_VERSION || { echo "Error: Failed to pull ChromaDB image"; exit 1; }
    docker pull ollama/ollama:$OLLAMA_VERSION || { echo "Error: Failed to pull Ollama image"; exit 1; }
    echo "✅ Docker images pulled successfully."

    # Create network
    create_network

    # Create volumes
    echo "Creating volumes..."
    docker volume create $OLLAMA_VOLUME
    docker volume create $CHROMA_VOLUME
    docker volume create $BACKEND_CACHE
    echo "✅ Volumes created."

    # Start Ollama
    echo "Starting Ollama..."
    docker run -d \
        -v $OLLAMA_VOLUME:/root/.ollama \
        -p 11434:11434 \
        --network $NETWORK_NAME \
        --name ollama \
        --restart unless-stopped \
        ollama/ollama:$OLLAMA_VERSION || { echo "Error: Failed to start Ollama"; exit 1; }
    echo "✅ Ollama started."

    # Pull model
    echo "Pulling model $MODEL_NAME..."
    sleep 5  # Give Ollama time to initialize
    docker exec ollama ollama pull $MODEL_NAME || { echo "Error: Failed to pull model $MODEL_NAME"; exit 1; }
    docker exec ollama ollama pull $EMBED_MODEL_NAME || { echo "Error: Failed to pull model $EMBED_MODEL_NAME"; exit 1; }
    echo "✅ Model $MODEL_NAME pulled."

    # Start ChromaDB
    echo "Starting ChromaDB..."
    docker run -d \
        -v $CHROMA_VOLUME:/chroma/chroma \
        -e ALLOW_RESET=true \
        -p 8000:8000 \
        --name chromadb \
        --restart unless-stopped \
        --network $NETWORK_NAME \
        chromadb/chroma:$CHROMA_VERSION || { echo "Error: Failed to start ChromaDB"; exit 1; }
    echo "✅ ChromaDB started."

    # Start Rapid Demo
    echo "Starting Rapid Demo..."
    docker run -d \
        -p 8080:8080 \
        --network $NETWORK_NAME \
        -v $BACKEND_CACHE:/root/.cache/ \
        --name rapid-demo \
        --restart unless-stopped \
        -e MODEL_NAME=$MODEL_NAME \
        ratish11/rapid-demo:$RAPID_DEMO_VERSION \
        /bin/bash -c "python run.py" || { echo "Error: Failed to start Rapid Demo"; exit 1; }
    echo "✅ Rapid Demo started."

    # Start Rapid Demo UI
    echo "Starting Rapid Demo UI..."
    docker run -d \
        -p 3000:3000 \
        --network $NETWORK_NAME \
        --name rapid-demo-ui \
        --restart unless-stopped \
        ratish11/rapid-demo-ui:$RAPID_DEMO_UI_VERSION || { echo "Error: Failed to start Rapid Demo UI"; exit 1; }
    echo "✅ Rapid Demo UI started."

    echo "Loading model into memory..."
    curl -s http://localhost:11434/api/generate -d "{ \"model\": \"$MODEL_NAME\", \"keep_alive\": -1}" > /dev/null || { echo "Warning: Failed to preload model. It will be loaded on first request."; }
    curl -s http://localhost:11434/api/generate -d "{ \"model\": \"$EMBED_MODEL_NAME\", \"keep_alive\": -1}" > /dev/null || { echo "Warning: Failed to preload embedding model. It will be loaded on first request."; }
    docker exec ollama ollama ps
    echo "✅ Installation complete!"
}

# Function to restart components
restart_components() {
    echo "Restarting WinGov AI components..."

    # Restart containers
    docker restart ollama chromadb rapid-demo rapid-demo-ui || { echo "Error: Failed to restart containers"; exit 1; }

    echo "✅ Components restarted."
}

# Function to display system status
display_status() {
    echo -e "\nWinGov AI System Status:"
    echo "------------------------"
    echo "Ollama: $(docker inspect --format '{{.State.Status}}' ollama 2>/dev/null || echo 'Not running')"
    echo "ChromaDB: $(docker inspect --format '{{.State.Status}}' chromadb 2>/dev/null || echo 'Not running')"
    echo "Rapid Demo: $(docker inspect --format '{{.State.Status}}' rapid-demo 2>/dev/null || echo 'Not running')"
    echo "Rapid Demo UI: $(docker inspect --format '{{.State.Status}}' rapid-demo-ui 2>/dev/null || echo 'Not running')"

    echo -e "\nOllama models:"
    docker exec ollama ollama list 2>/dev/null || echo "Cannot list models - Ollama not running"

    echo -e "\nAccess the application at:"
    echo "UI: http://localhost:3000"
#    echo "API: http://localhost:8080"
}

# Main execution
echo "WinGov AI Installation Script"
echo "============================"
echo "Action: $ACTION"
echo "Model: $MODEL_NAME"
echo "Embedding Model: $EMBED_MODEL_NAME"
echo "----------------------------"

# Check Docker installation
check_docker

# Execute requested action
case $ACTION in
    clean)
        clean_install
        install_components
        display_status
        ;;
    install)
        stop_containers
        remove_containers
        install_components
        display_status
        ;;
    restart)
        restart_components
        display_status
        ;;
    stop)
        stop_containers
        echo "✅ WinGov AI stopped."
        ;;
    *)
        echo "Unknown action: $ACTION"
        print_usage
        ;;
esac

exit 0
