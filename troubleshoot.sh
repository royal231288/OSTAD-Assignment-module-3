#!/bin/bash

echo "=== Site Accessibility Troubleshooting ==="
echo "Timestamp: $(date)"
echo ""

# 1. Check if application is running
echo "1. APPLICATION STATUS CHECK"
echo "=========================="

# Check PM2 status
echo "PM2 Status:"
if command -v pm2 &> /dev/null; then
    pm2 status
    echo ""
    echo "PM2 Logs (last 10 lines):"
    pm2 logs node-express-app --lines 10 --nostream 2>/dev/null || echo "No PM2 logs found"
else
    echo "PM2 not installed"
fi
echo ""

# Check Node.js processes
echo "Node.js Processes:"
ps aux | grep -v grep | grep node || echo "No Node.js processes found"
echo ""

# 2. Check port status
echo "2. PORT STATUS CHECK"
echo "==================="

# Check what's listening on port 3000
echo "Port 3000 status:"
if command -v lsof &> /dev/null; then
    sudo lsof -i :3000 || echo "Nothing listening on port 3000"
else
    netstat -tlnp | grep :3000 || echo "Nothing listening on port 3000"
fi
echo ""

# Check all listening ports
echo "All listening ports:"
if command -v ss &> /dev/null; then
    ss -tlnp | grep LISTEN
else
    netstat -tlnp | grep LISTEN
fi
echo ""

# 3. Test local connectivity
echo "3. LOCAL CONNECTIVITY TEST"
echo "=========================="

# Test localhost:3000
echo "Testing http://localhost:3000/api:"
if curl -f -s --connect-timeout 5 http://localhost:3000/api; then
    echo "✅ localhost:3000/api is responding"
    echo "Response: $(curl -s http://localhost:3000/api)"
else
    echo "❌ localhost:3000/api is not responding"
fi
echo ""

# Test 127.0.0.1:3000
echo "Testing http://127.0.0.1:3000/api:"
if curl -f -s --connect-timeout 5 http://127.0.0.1:3000/api; then
    echo "✅ 127.0.0.1:3000/api is responding"
else
    echo "❌ 127.0.0.1:3000/api is not responding"
fi
echo ""

# 4. Check network interfaces
echo "4. NETWORK INTERFACE CHECK"
echo "=========================="

echo "Network interfaces:"
ip addr show || ifconfig
echo ""

echo "Server IP addresses:"
hostname -I 2>/dev/null || echo "Could not determine IP addresses"
echo ""

# 5. Test external connectivity
echo "5. EXTERNAL CONNECTIVITY TEST"
echo "============================="

# Get server's external IP
EXTERNAL_IP=$(curl -s http://checkip.amazonaws.com/ 2>/dev/null || echo "unknown")
echo "External IP: $EXTERNAL_IP"

# Test external access
if [ "$EXTERNAL_IP" != "unknown" ]; then
    echo "Testing http://$EXTERNAL_IP:3000/api:"
    if curl -f -s --connect-timeout 10 http://$EXTERNAL_IP:3000/api; then
        echo "✅ External access working"
    else
        echo "❌ External access not working"
    fi
else
    echo "Could not determine external IP for testing"
fi
echo ""

# 6. Check firewall status
echo "6. FIREWALL STATUS CHECK"
echo "======================="

# Check ufw (Ubuntu/Debian)
if command -v ufw &> /dev/null; then
    echo "UFW Status:"
    sudo ufw status
    echo ""
fi

# Check firewalld (CentOS/RHEL)
if command -v firewall-cmd &> /dev/null; then
    echo "Firewalld Status:"
    sudo firewall-cmd --list-all
    echo ""
fi

# Check iptables
if command -v iptables &> /dev/null; then
    echo "Iptables rules (INPUT chain):"
    sudo iptables -L INPUT -n
    echo ""
fi

# 7. Check deployment directory
echo "7. DEPLOYMENT DIRECTORY CHECK"
echo "============================="

DEPLOY_DIR="/opt/node-apps"
if [ -d "$DEPLOY_DIR" ]; then
    echo "Deployment directory exists: $DEPLOY_DIR"
    ls -la $DEPLOY_DIR/
    echo ""
    
    # Check for specific app directory
    APP_DIR=$(find $DEPLOY_DIR -name "*Assignment*" -type d | head -1)
    if [ -n "$APP_DIR" ]; then
        echo "Application directory: $APP_DIR"
        ls -la "$APP_DIR/"
        echo ""
        
        # Check if server.js exists
        if [ -f "$APP_DIR/src/server.js" ]; then
            echo "✅ server.js found at $APP_DIR/src/server.js"
        else
            echo "❌ server.js not found"
        fi
        
        # Check package.json
        if [ -f "$APP_DIR/package.json" ]; then
            echo "✅ package.json found"
            echo "Package info:"
            cat "$APP_DIR/package.json" | grep -E '"name"|"version"|"scripts"' -A 3
        else
            echo "❌ package.json not found"
        fi
    else
        echo "❌ Application directory not found in $DEPLOY_DIR"
    fi
else
    echo "❌ Deployment directory does not exist: $DEPLOY_DIR"
fi
echo ""

# 8. System resource check
echo "8. SYSTEM RESOURCES CHECK"
echo "========================="

echo "Memory usage:"
free -h
echo ""

echo "Disk usage:"
df -h
echo ""

echo "CPU load:"
uptime
echo ""

# 9. Check logs
echo "9. SYSTEM LOGS CHECK"
echo "==================="

echo "Recent system logs (last 20 lines):"
sudo journalctl -n 20 --no-pager 2>/dev/null || echo "Could not access system logs"
echo ""

# 10. Recommendations
echo "10. TROUBLESHOOTING RECOMMENDATIONS"
echo "=================================="

echo "Based on the checks above, here are potential solutions:"
echo ""

# Check if PM2 is running
if ! pgrep -f pm2 > /dev/null; then
    echo "🔧 PM2 is not running. Try:"
    echo "   pm2 start /path/to/your/app/src/server.js --name node-express-app"
    echo ""
fi

# Check if port 3000 is free
if ! sudo lsof -i :3000 > /dev/null 2>&1; then
    echo "🔧 Nothing is listening on port 3000. Try:"
    echo "   cd /opt/node-apps/your-app && node src/server.js"
    echo ""
fi

# Check firewall
echo "🔧 If the app is running but not accessible externally:"
echo "   sudo ufw allow 3000  # Ubuntu/Debian"
echo "   sudo firewall-cmd --permanent --add-port=3000/tcp && sudo firewall-cmd --reload  # CentOS/RHEL"
echo ""

echo "🔧 Manual start command:"
echo "   cd /opt/node-apps/OSTAD-Assignment-module-3 && npm start"
echo ""

echo "=== End of Troubleshooting Report ==="
