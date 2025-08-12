#!/bin/bash

OS_TYPE="$(uname -s)"

# Install trufflehog using the convenience script curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
# But on Windows install to ~/bin instead of /usr/local/bin
# Else install it to a non admin location that's local to home. 

# If msys
if [[ "$OSTYPE" == "msys" ]]; then
    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b ~/bin
elif [[ "$OS_TYPE" == "Linux" ]]; then
    sudo curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
else
    echo "Unsupported OS type: $OS_TYPE"
    exit 1
fi

if ! command -v trufflehog &> /dev/null; then
    echo "TruffleHog installation failed, sorry! Please check your internet connection or the installation script."
    exit 1
fi

TRUFFLEHOG_CMD=$(which trufflehog)
echo "TruffleHog installed successfully at $TRUFFLEHOG_CMD"

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