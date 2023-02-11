FROM debian:buster

MAINTAINER tweak4141, <tweak@talosbot.xyz>

# Basic dependencies
RUN apt update \
    && apt upgrade -y \
    && apt -y install curl wget software-properties-common locales git liblzma-dev lzma cmake \
    && adduser container 
      
# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# OpenJDK 17 LTS
RUN apt update \
   && apt install -y libc6-i386 libc6-x32 \
   && wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb -O jdk-17_linux-x64_bin.deb \
   && apt install -y ./jdk-17_linux-x64_bin.deb \
   && rm jdk-17_linux-x64_bin.deb \
   && apt install -y default-jre
   
ENV JAVA_HOME=/usr/lib/jvm/jdk-17/
ENV PATH=$PATH:$JAVA_HOME/bin

# Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.67.0

RUN set -eux; \
    rustArch='x86_64-unknown-linux-gnu'; \
    rustupSha256='5cc9ffd1026e82e7fb2eec2121ad71f4b0f044e88bca39207b3f6b769aaa799c'; \
    url="https://static.rust-lang.org/rustup/archive/1.25.1/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; 
    
# NodeJS
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt -y install nodejs \
    && apt -y install ffmpeg \
    && apt -y install make \
    && apt -y install build-essential 
    
# Python 2 & 3
RUN apt update \
   && apt -y install zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev \
   && wget https://www.python.org/ftp/python/3.10.9/Python-3.10.9.tgz \
   && tar -xf Python-3.10.*.tgz \
   && cd Python-3.10.9 \
   && ./configure --enable-optimizations \
   && make -j $(nproc) \
   && make altinstall \
   && cd .. \
   && rm -rf Python-3.10.9 \
   && rm Python-3.10.*.tgz 
   
# Upgrade Pip
RUN apt -y install python python-pip python3-pip \
   && pip3 install --upgrade pip

# Golang
RUN curl -OL https://golang.org/dl/go1.19.4.linux-amd64.tar.gz \
   && tar -C /usr/local -xvf go1.19.4.linux-amd64.tar.gz   
ENV PATH=$PATH:/usr/local/go/bin
ENV GOROOT=/usr/local/go

#.NET Core Runtime and SDK
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
   && dpkg -i packages-microsoft-prod.deb \ 
   && rm packages-microsoft-prod.deb \
   && apt update \
   && apt install -y apt-transport-https \
   && apt update \
   && apt install -y aspnetcore-runtime-6.0 dotnet-sdk-6.0 

# Install the system dependencies required for puppeteer support
RUN apt-get install -y \
    fonts-liberation \
    gconf-service \
    libappindicator1 \
    libasound2 \
    libatk1.0-0 \
    libcairo2 \
    libcups2 \
    libfontconfig1 \
    libgbm-dev \
    libgdk-pixbuf2.0-0 \
    libgtk-3-0 \
    libicu-dev \
    libjpeg-dev \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpng-dev \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    xdg-utils

# Installing NodeJS dependencies for AIO.
RUN npm i -g yarn pm2 


USER container
ENV  USER container
ENV  HOME /home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
