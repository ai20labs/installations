!#/bin/bash
#docker build  --no-cache  -t rapid-demo-ui:1.0.0 . #for building images
if ! command -v docker &> /dev/null
then
  echo "Docker is not installed. Trying to install with brew, if fails, please install docker \n ref: https://docs.docker.com/desktop/setup/install/mac-install/"
  # Add commands to execute if Docker is not installed here, for example:
  brew install docker
  if [ $? -eq 0 ]; then
    echo "docker imstallation successful, starting docker service"
    open -a Docker
    
  else
    echo "docker installation failed, exiting, try installing docker manually and then rerun this script"
    exit 1
  fi
else
  echo "Docker is installed. proceeding.."
fi

# open --background -a Docker
  docker pull ratish11/rapid-demo:1.0.3
  docker pull ratish11/rapid-demo-ui:1.0.2
  docker pull chromadb/chroma:0.6.3
  docker pull ollama/ollama
  docker network create -d bridge rapid-demo-network
  docker volume create ollama chroma-data
  docker run -d -v ollama:/root/.ollama -p 11434:11434 --network rapid-demo-network --name ollama ollama/ollama
  docker exec ollama ollama pull deepseek-r1
  docker run -d -v chroma-data:/data -e ALLOW_RESET=true -p 8000:8000 --name chromadb --network   rapid-demo-network chromadb/chroma:0.6.3
  docker run -d -p 8080:8080 --network rapid-demo-network --name rapid-demo rapid-demo:1.0.3
  docker run -d -p 3000:3000 --network rapid-demo-network --name rapid-demo-ui rapid-demo-ui:1.0.2
