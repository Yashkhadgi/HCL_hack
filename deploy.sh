#!/bin/bash

# Navigate to the project root directory
cd "$(dirname "$0")" || exit

echo "Fetching latest changes from origin..."
git fetch origin main

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

# Check if the code is up to date
if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates found! Pulling latest code from main branch..."
    git pull origin main
    
    echo "Installing dependencies..."
    npm install
else
    echo "Code is already up-to-date with the main branch."
    
    # Just in case node_modules is missing
    if [ ! -d "node_modules" ]; then
        echo "node_modules not found, installing dependencies..."
        npm install
    fi
fi

# Check if pm2 is installed globally, install if missing
# pm2 is a process manager that keeps your app running in the background
if ! npx pm2 --version &> /dev/null
then
    echo "pm2 not found. Installing pm2 globally..."
    npm install -g pm2
fi

# To access the site just using the public IP (without :3000), 
# we forward traffic from port 80 (default HTTP port) to port 3000.
echo "Setting up port forwarding from port 80 to 3000..."
sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3000

echo "Starting/Restarting the Next.js dev server with PM2..."

# Stop and delete the existing pm2 instance if it exists to refresh it
npx pm2 delete next-dev-server 2>/dev/null || true

# Start Next.js dev server on all network interfaces
# Note: For production, it's highly recommended to use 'npm run build' followed by 'npm start'
# instead of 'npm run dev' to ensure better performance.
npx pm2 start npm --name "next-dev-server" -- run dev -- -H 0.0.0.0 -p 3000

# Save the pm2 process list so it restarts on system reboot (optional)
npx pm2 save

echo ""
echo "=========================================================================="
echo "✅ Deployment complete!"
echo "Your dev server is now running in the background."
echo "You can access your frontend by simply visiting your EC2's Public IP in a browser."
echo ""
echo "IMPORTANT AWS SETUP:"
echo "Make sure that your AWS EC2 Security Group has an Inbound Rule allowing HTTP (Port 80) traffic from anywhere (0.0.0.0/0)."
echo ""
echo "To view live server logs, run: npx pm2 logs next-dev-server"
echo "To stop the server, run: npx pm2 stop next-dev-server"
echo "=========================================================================="
