#!/bin/bash

case "$1" in
    start)
        echo "Starting SSH tunnels..."
        ./setup-ssh-tunnel-monitoring.sh
        ;;
    stop)
        echo "Stopping SSH tunnels..."
        pkill -f "ssh.*910[0-9]"
        echo "SSH tunnels stopped"
        ;;
    status)
        echo "SSH Tunnel Status:"
        ps aux | grep "ssh.*910[0-9]" | grep -v grep || echo "No tunnels running"
        ;;
    restart)
        echo "Restarting SSH tunnels..."
        pkill -f "ssh.*910[0-9]"
        sleep 2
        ./setup-ssh-tunnel-monitoring.sh
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
