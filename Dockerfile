FROM ubuntu:22.04

# ============================================
# 1. INSTALL DESKTOP & DEPENDENCIES
# ============================================
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt upgrade -y && \
    apt install --no-install-recommends -y \
        software-properties-common \
        wget \
        curl \
        sudo \
        xfce4 \
        xfce4-goodies \
        dbus-x11 \
        x11-xserver-utils \
        x11-utils \
        x11vnc \
        novnc \
        websockify \
        firefox \
        tzdata \
        nano \
        vim \
        git \
        net-tools \
        iputils-ping \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 2. INSTALL CHROME REMOTE DESKTOP
# ============================================
RUN wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    apt install -y ./chrome-remote-desktop_current_amd64.deb && \
    rm chrome-remote-desktop_current_amd64.deb

# ============================================
# 3. CREATE ADMIN USER
# ============================================
RUN useradd -m -s /bin/bash admin && \
    echo "admin:7388" | chpasswd && \
    usermod -aG sudo admin && \
    echo "admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ============================================
# 4. FIX XWRAPPER PERMISSIONS
# ============================================
RUN sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# ============================================
# 5. CONFIGURE CHROME REMOTE DESKTOP SESSION
# ============================================
RUN mkdir -p /etc/chrome-remote-desktop && \
    echo 'exec /usr/bin/startxfce4' > /etc/chrome-remote-desktop/session && \
    echo "1920x1080" > /etc/chrome-remote-desktop/desktop-sizes

# ============================================
# 6. YOUR CHROME RDP COMMAND - AUTHORIZATION
# ============================================
RUN DISPLAY= /opt/google/chrome-remote-desktop/start-host \
    --code="4/0ASc3gC3PNCb3N4ouWdJq9336vM64MVhnmTAP4Rsk4yz7nDB3rzb3l4lZshz7UQxziTPpUA" \
    --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
    --name=$(hostname)

# ============================================
# 7. START CHROME RDP ON CONTAINER START
# ============================================
RUN echo '#!/bin/bash\n\
# Start Chrome Remote Desktop service\n\
/opt/google/chrome-remote-desktop/chrome-remote-desktop --start &\n\
\n\
echo "========================================="\n\
echo "✅ Chrome Remote Desktop is READY!"\n\
echo "========================================="\n\
echo "📱 Connect at: https://remotedesktop.google.com/access"\n\
echo "👤 Username: admin"\n\
echo "🔑 Password: 7388"\n\
echo "========================================="\n\
\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

# ============================================
# 8. SET DEFAULT COMMAND
# ============================================
CMD ["/start.sh"]

# Expose ports (optional)
EXPOSE 8080 3389 5901
