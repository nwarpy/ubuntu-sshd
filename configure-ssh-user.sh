#!/bin/bash

# Set default values for SSH_USERNAME and SSH_PASSWORD if not provided
: ${SSH_USERNAME:=ubuntu}
: ${SSH_PASSWORD:?"Error: SSH_PASSWORD environment variable is not set."}
: ${SSHD_CONFIG_ADDITIONAL:=""}

# Create the user with the provided username and set the password
if id "$SSH_USERNAME" &>/dev/null; then
    echo "User $SSH_USERNAME already exists"
else
    useradd -ms /bin/bash "$SSH_USERNAME"
    echo "$SSH_USERNAME:$SSH_PASSWORD" | chpasswd
    echo "User $SSH_USERNAME created with the provided password"
fi

# Set the authorized keys from the AUTHORIZED_KEYS environment variable (if provided)
mkdir -p /home/$SSH_USERNAME/.ssh
chown -R $SSH_USERNAME:$SSH_USERNAME /home/$SSH_USERNAME
chmod 700 /home/$SSH_USERNAME/.ssh
if [ -n "$AUTHORIZED_KEYS" ]; then
    echo "$AUTHORIZED_KEYS" > /home/$SSH_USERNAME/.ssh/authorized_keys
    chmod 600 /home/$SSH_USERNAME/.ssh/authorized_keys
    echo "Authorized keys set for user $SSH_USERNAME"
    # Disable password authentication if authorized keys are provided
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# Apply additional SSHD configuration if provided
if [ -n "$SSHD_CONFIG_ADDITIONAL" ]; then
    echo "$SSHD_CONFIG_ADDITIONAL" >> /etc/ssh/sshd_config
    echo "Additional SSHD configuration applied"
fi

# Apply additional SSHD configuration from a file if provided
if [ -n "$SSHD_CONFIG_FILE" ] && [ -f "$SSHD_CONFIG_FILE" ]; then
    cat "$SSHD_CONFIG_FILE" >> /etc/ssh/sshd_config
    echo "Additional SSHD configuration from file applied"
fi

if [ ! -f /home/$SSH_USERNAME/.ssh/id_ed25519 ]; then
    echo "/home/$SSH_USERNAME/.ssh/id_ed25519 not found, creating..."
    ssh-keygen -t ed25519 -N "" -f /home/$SSH_USERNAME/.ssh/id_ed25519
fi
cat /home/$SSH_USERNAME/.ssh/id_ed25519.pub

# Start the SSH server
echo "Starting SSH server..."
exec /usr/sbin/sshd -D
