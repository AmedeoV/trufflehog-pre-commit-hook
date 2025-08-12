#!/bin/bash


# Check if trufflehog is already installed, else use the trufflehog convenience scripts. 
if command -v trufflehog &> /dev/null; then
    echo "TruffleHog is already installed."
else
  if [[ "$OSTYPE" == "msys" ]]; then
      curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b ~/bin
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      mkdir -p ~/.local/bin
      curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b ~/.local/bin
  elif [[ "$OSTYPE" == "darwin"* ]]; then
      curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
  else
      echo "Unsupported OS type: $OS_TYPE"
      exit 1
  fi
  
  if ! command -v trufflehog &> /dev/null; then
      echo "TruffleHog installation failed, sorry! Please check your internet connection or the installation script."
      exit 1
  fi

fi

TRUFFLEHOG_CMD=$(which trufflehog)
echo "TruffleHog installed at $TRUFFLEHOG_CMD"

echo "Creating .git-hooks directory..."
mkdir -p ~/.git-hooks
echo ".git-hooks directory created."

echo "Writing custom-detectors.yaml..."
cat << 'YAML' > ~/custom-detectors.yaml
detectors:
  - name: Hardcoded Password
    keywords:
      - password
    regex:
      password: 'password\s*=\s*.+'
    verify: []
YAML
echo "custom-detectors.yaml created."

echo "Configuring git to use custom hooks path..."
git config --global core.hooksPath ~/.git-hooks
echo "Git hooks path configured."

echo "Writing pre-commit hook file..."
cat << EOF > ~/.git-hooks/pre-commit
#!/bin/sh

$TRUFFLEHOG_CMD git file://. --since-commit HEAD --config ~/custom-detectors.yaml --fail
EOF
echo "pre-commit file created."

echo "Setting pre-commit file as executable..."
chmod +x ~/.git-hooks/pre-commit
echo "pre-commit file is now executable."
echo "Script ran successfully."