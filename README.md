# WinGov AI

WinGov AI is an LLM-based application that leverages GPU resources for optimal performance.

## Prerequisites

- **Docker Desktop**: Required for running the application components
  - [Install Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
  - [Install Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
- **Git Bash** (for Windows users only): Required for running the installation script
  - [Download Git Bash](https://git-scm.com/downloads/win)
- **GPU**: Recommended for optimal performance
- **Internet Connection**: Required for downloading Docker images

## Installation

1. Ensure Docker Desktop is installed and running on your system.

2. Open Terminal (Mac/Linux) or Git Bash (Windows).

3. Run the following command to download and execute the installation script:

   ```bash
   curl -O https://raw.githubusercontent.com/ai20labs/installations/refs/heads/main/run_script.sh && chmod +x run_script.sh && ./run_script.sh
   ```

   This script will:
   - Verify Docker is installed
   - Stop and remove any existing containers with the same names
   - Pull necessary Docker images
   - Create a Docker network and volumes
   - Set up and start required services:
     - Ollama (LLM serving)
     - ChromaDB (Vector database)
     - Rapid Demo API
     - Rapid Demo UI
   - Load the Gemma 3:1B model into memory

## System Architecture

WinGov AI consists of the following components:

- **Ollama**: Serves the LLM model (Gemma 3:1B)
- **ChromaDB**: Vector database for efficient document retrieval
- **Rapid Demo API**: Backend service
- **Rapid Demo UI**: Frontend interface

## Accessing the Application

After installation, you can access the application at:
- UI: [http://localhost:3000](http://localhost:3000)
- API: [http://localhost:8080](http://localhost:8080)

## Troubleshooting

### Docker Not Running
If you encounter errors related to Docker not running, ensure Docker Desktop is started before running the installation script.

### Port Conflicts
If you see errors about ports being already in use, check if other applications are using ports 3000, 8000, 8080, or 11434.

### Memory Issues
If the application performs slowly or crashes, ensure your system has sufficient RAM and GPU memory available.

## Maintenance

### Updating
To update to the latest version:
1. Stop all containers
2. Re-run the installation script

### Stopping Services
To stop all services:
```bash
docker stop rapid-demo-ui rapid-demo chromadb ollama
```

### Removing Services
To remove all services and data:
```bash
docker stop rapid-demo-ui rapid-demo chromadb ollama
docker rm -f rapid-demo-ui rapid-demo chromadb ollama
docker volume rm ollama chroma-data
docker network rm rapid-demo-network
```

## System Requirements

- **Minimum**: 8GB RAM, 4 CPU cores, 10GB free disk space
- **Recommended**: 16GB RAM, 8 CPU cores, GPU with 4GB+ VRAM, 20GB free disk space
