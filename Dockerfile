FROM ubuntu:22.04

# ============================================
# 1. INSTALL DESKTOP + VNC + noVNC
# ============================================
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    wget \
    curl \
    firefox \
    dbus-x11 \
    x11-xserver-utils \
    nano \
    vim \
    git \
    net-tools \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 2. CREATE ADMIN USER
# ============================================
RUN useradd -m -s /bin/bash admin && \
    echo "admin:7388" | chpasswd && \
    echo "admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ============================================
# 3. SETUP VNC SERVER
# ============================================
RUN mkdir -p /home/admin/.vnc && \
    echo '#!/bin/bash\nxrdb $HOME/.Xresources\nstartxfce4 &' > /home/admin/.vnc/xstartup && \
    chmod +x /home/admin/.vnc/xstartup && \
    echo "7388" | vncpasswd -f > /home/admin/.vnc/passwd && \
    chmod 600 /home/admin/.vnc/passwd && \
    chown -R admin:admin /home/admin/.vnc

# ============================================
# 4. FIX XWRAPPER PERMISSIONS
# ============================================
RUN sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# ============================================
# 5. STARTUP SCRIPT
# ============================================
RUN echo '#!/bin/bash\n\
# Start VNC server as admin\n\
su - admin -c "vncserver :1 -geometry 1920x1080 -depth 24 -localhost no" &\n\
sleep 3\n\
\n\
# Start noVNC web interface\n\
websockify -D --web=/usr/share/novnc/ 8080 localhost:5901\n\
sleep 2\n\
\n\
echo "========================================="\n\
echo "✅ VNC + noVNC is READY!"\n\
echo "========================================="\n\
echo "🌐 Web Access:  https://YOUR-RAILWAY-URL:8080/vnc.html"\n\
echo "🔑 Password:    7388"\n\
echo "👤 Username:    admin"\n\
echo "========================================="\n\
\n\
# Keep container alive\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

# ============================================
# 6. EXPOSE PORTS
# ============================================
EXPOSE 8080 5901

# ============================================
# 7. START CONTAINER
# ============================================
CMD ["/start.sh"]
