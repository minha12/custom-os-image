#!/bin/bash

# Bash script to install XFCE and TightVNC Server on a Debian-based system

# Updating the package list
echo "Updating package list..."
sudo apt-get update

# Install XFCE desktop environment
echo "Installing XFCE..."
sudo apt-get install xfce4 xfce4-goodies -y
sudo apt-get install xfonts-base -y

# Install TightVNC server
echo "Installing TightVNC server..."
sudo apt-get install tightvncserver -y

# Start the VNC server to create the initial default config
echo "Starting VNC server for initial configuration..."
if ! vncserver :1; then
    echo "Failed to start VNC server. Exiting."
    exit 1
fi

# Prompt user for setting VNC password if it's not already set
echo "You will now be prompted to set your VNC password if not set already."

# Stop VNC server for proper configuration
vncserver -kill :1

# Back up and configure the VNC xstartup file to run the XFCE desktop environment
echo "Configuring VNC to use XFCE Desktop..."
mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

# Path to the VNC xstartup file
XSTARTUP_FILE="$HOME/.vnc/xstartup"

# Check if the file exists        
if [ ! -f "$XSTARTUP_FILE" ]; then
    echo "$XSTARTUP_FILE does not exist. Creating a new one."
    # Create the file and add the necessary content
    cat <<EOL > "$XSTARTUP_FILE"
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
EOL
    # Make xstartup executable
    chmod +x "$XSTARTUP_FILE"
else
    # If the file exists, check if the 'startxfce4 &' line already exists
    if grep -Fxq "startxfce4 &" "$XSTARTUP_FILE"; then
        echo "'startxfce4 &' already exists in $XSTARTUP_FILE"
    else
        echo "'startxfce4 &' not found. Adding it to $XSTARTUP_FILE"
        # Add 'startxfce4 &' to the end of the file if it doesn't exist
        echo "startxfce4 &" >> "$XSTARTUP_FILE"
    fi
fi

# Optional: Create systemd service for automatic VNC start on boot
read -p "Do you want to create a systemd service to automatically start VNC on boot? (y/n): " create_service
if [[ $create_service == "y" || $create_service == "Y" ]]; then
    echo "Creating VNC systemd service..."
    sudo bash -c 'cat << EOF > /etc/systemd/system/vncserver@:1.service
[Unit]
Description=Start TightVNC for user %i at display :1
After=network.target

[Service]
Type=forking
User=$USER
WorkingDirectory=/home/$USER
PAMName=login
PIDFile=/home/$USER/.vnc/%H:1.pid
ExecStartPre=-/usr/bin/vncserver -kill :1 > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :1 -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
EOF'

    # Reload systemd to recognize the new service
    sudo systemctl daemon-reload

    # Enable VNC service (start on boot)
    sudo systemctl enable vncserver@:1.service
    echo "VNC systemd service created and enabled."
else
    echo "Skipping systemd service creation."
fi

echo "VNC server and XFCE installation complete."
echo "To start VNC again, use: vncserver :1"

# Completed the setup
echo "XFCE and TightVNC server installation is complete!"

