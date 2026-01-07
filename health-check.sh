#!/bin/bash

# Health Check Script for Node.js Application
echo "=== Application Health Check ==="
echo "Timestamp: $(date)"
echo ""

# Check PM2 status
echo "1. PM2 Process Status:"
if command -v pm2 &> /dev/null; then
    pm2 status node-express-app 2>/dev/null || echo "   ❌ PM2 process 'node-express-app' not found"
else
    echo "   ❌ PM2 not installed"
fi
echo ""

# Check port 3000
echo "2. Port 3000 Status:"
if sudo lsof -i :3000 &> /dev/null; then
    echo "   ✅ Port 3000 is in use"
    sudo lsof -i :3000
else
    echo "   ❌ Port 3000 is not in use"
fi
echo ""

# Check HTTP endpoint
echo "3. HTTP Endpoint Test:"
if curl -f -s http://localhost:3000/api > /dev/null; then
    echo "   ✅ API endpoint is responding"
    echo "   Response: $(curl -s http://localhost:3000/api)"
else
    echo "   ❌ API endpoint is not responding"
fi
echo ""

# Check Node.js processes
echo "4. Node.js Processes:"
NODE_PROCESSES=$(ps aux | grep -v grep | grep "node.*server.js" | wc -l)
if [ $NODE_PROCESSES -gt 0 ]; then
    echo "   ✅ Found $NODE_PROCESSES Node.js process(es)"
    ps aux | grep -v grep | grep "node.*server.js"
else
    echo "   ❌ No Node.js server processes found"
fi
echo ""

# Check system resources
echo "5. System Resources:"
echo "   Memory usage: $(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')"
echo "   Disk usage: $(df -h / | awk 'NR==2{print $5}')"
echo "   Load average: $(uptime | awk -F'load average:' '{ print $2 }')"
echo ""

# Overall status
if curl -f -s http://localhost:3000/api > /dev/null && [ $NODE_PROCESSES -gt 0 ]; then
    echo "🟢 Overall Status: HEALTHY"
    exit 0
else
    echo "🔴 Overall Status: UNHEALTHY"
    exit 1
fi
