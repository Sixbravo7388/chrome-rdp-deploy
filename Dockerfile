FROM ubuntu:22.04

# 1. Install everything (including tigervnc-tools!)
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-tools \
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

# 2. Create user 'admin' with password '7388'
RUN useradd -m -s /bin/bash admin && \
    echo "admin:7388" | chpasswd && \
    echo "admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Set up VNC password and xstartup
RUN mkdir -p /home/admin/.vnc && \
    echo '#!/bin/bash\nxrdb $HOME/.Xresources\nstartxfce4 &' > /home/admin/.vnc/xstartup && \
    chmod +x /home/admin/.vnc/xstartup && \
    echo "7388" | vncpasswd -f > /home/admin/.vnc/passwd && \
    chmod 600 /home/admin/.vnc/passwd && \
    chown -R admin:admin /home/admin/.vnc

# 4. Fix Xwrapper (allow any user to start X)
RUN sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# 5. Expose VNC (5901) and noVNC web (8080)
EXPOSE 5901 8080

# 6. Start VNC + noVNC
CMD su - admin -c "vncserver :1 -geometry 1280x720 -depth 24 -localhost no && websockify -D --web=/usr/share/novnc/ 8080 localhost:5901 && tail -f /dev/null"
