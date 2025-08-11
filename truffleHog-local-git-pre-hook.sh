#!/bin/bash

OS_TYPE="$(uname -s)"

# Set trufflehog command based on OS
if [[ "$OS_TYPE" =~ MINGW|MSYS|CYGWIN ]]; then
  TRUFFLEHOG_CMD="/usr/local/bin/trufflehog"
else
  TRUFFLEHOG_CMD="trufflehog"
fi

if [[ "$OS_TYPE" =~ MINGW|MSYS|CYGWIN ]]; then
  # Windows-specific admin check
  net session > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Please run Git Bash as administrator."
    read -p "Press enter to exit"
    exit 1
  fi
  INSTALL_TRUFFLEHOG="curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin"
elif [[ "$OS_TYPE" == "Darwin" ]]; then
  # macOS: install as invoking user, not root
  if [ -n "$SUDO_USER" ]; then
    INSTALL_TRUFFLEHOG="sudo -u \"$SUDO_USER\" brew install trufflehog"
  else
    INSTALL_TRUFFLEHOG="brew install trufflehog"
  fi
elif [[ "$OS_TYPE" == "Linux" ]]; then
  # Linux admin check
  if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as an administrator (use sudo)."
    read -p "Press enter to exit"
    exit 1
  fi
  INSTALL_TRUFFLEHOG="curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin"
else
  echo "Unknown OS: $OS_TYPE. Skipping setup."
  exit 0
fi

echo "Installing trufflehog..."
eval $INSTALL_TRUFFLEHOG
echo "trufflehog installation complete."

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
read -p "Press enter to exit"