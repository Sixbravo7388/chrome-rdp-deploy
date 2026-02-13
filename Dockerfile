FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================
# 1. BASE DEPENDENCIES
# ============================================
RUN apt update -y && apt upgrade -y && \
    apt install --no-install-recommends -y \
        wget \
        curl \
        sudo \
        xfce4 \
        xfce4-goodies \
        dbus-x11 \
        x11-xserver-utils \
        firefox \
        tzdata \
        nano \
        vim \
        git \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 2. CHROME RD DEPENDENCIES (FIXES ERROR 100)
# ============================================
RUN apt update -y && apt install -y \
    libgbm1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libxss1 \
    --no-install-recommends \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 3. INSTALL CHROME REMOTE DESKTOP
# ============================================
RUN wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    apt install -y ./chrome-remote-desktop_current_amd64.deb && \
    rm chrome-remote-desktop_current_amd64.deb

# ============================================
# 4. CREATE ADMIN USER
# ============================================
RUN useradd -m -s /bin/bash admin && \
    echo "admin:7388" | chpasswd && \
    usermod -aG sudo admin && \
    echo "admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ============================================
# 5. FIX XWRAPPER
# ============================================
RUN sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# ============================================
# 6. CONFIGURE CHROME RD SESSION
# ============================================
RUN mkdir -p /etc/chrome-remote-desktop && \
    echo 'exec /usr/bin/startxfce4' > /etc/chrome-remote-desktop/session && \
    echo "1920x1080" > /etc/chrome-remote-desktop/desktop-sizes

# ============================================
# 7. YOUR CHROME RDP AUTHORIZATION COMMAND
# ============================================
RUN DISPLAY= /opt/google/chrome-remote-desktop/start-host \
    --code="4/0ASc3gC23QAo2D206FVBsVJkDPYkkGwSnHTdNGtls_OJstZ48KSUPw2GOY2QNvLTqHmTTVg" \
    --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
    --name=$(hostname)

# ============================================
# 8. STARTUP SCRIPT
# ============================================
RUN echo '#!/bin/bash\n\
echo "========================================="\n\
echo "🚀 Starting Chrome Remote Desktop..."\n\
echo "========================================="\n\
/opt/google/chrome-remote-desktop/chrome-remote-desktop --start &\n\
echo "✅ Chrome RD running!"\n\
echo "📱 Connect at: https://remotedesktop.google.com/access"\n\
echo "👤 Username: admin"\n\
echo "🔑 Password: 7388"\n\
echo "========================================="\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
