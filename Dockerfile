# Kudos to DOROWU for his amazing VNC 18.04 LXDE image
FROM dorowu/ubuntu-desktop-lxde-vnc:bionic AS mipal-swift
LABEL maintainer "info@mipal.net.au"

RUN apt-get update && apt-get upgrade -y && apt-get install -y git curl wget dirmngr

#
# Install development environment
#
ARG LLVMVER=8
ENV LLVMVER=$LLVMVER
RUN apt-get -y install git git-svn build-essential libc++-dev clang bmake pmake cmake ninja-build llvm-${LLVMVER}-dev libclang-${LLVMVER}-dev libblocksruntime-dev libkqueue-dev libpthread-workqueue-dev libavahi-core-dev libavahi-client-dev libavahi-common-dev libavahi-compat-libdnssd1 python-dev ruby-dev libicu-dev ghc libffi-dev libcairo2-dev libart-2.0-dev portaudio19-dev libxslt1-dev libreadline-dev libjpeg-turbo8-dev libtiff5-dev libpng-dev libgif-dev libgnutls28-dev libsndfile1-dev libasound2-dev alsa-oss libao-dev libaspell-dev libxt-dev libxext-dev libxft-dev mdns-scan autoconf libtool libedit-dev libssl-dev swig libgmp-dev libmpfr6 libmpfr-dev libmpc-dev subversion libcups2-dev flite1-dev liblldb-${LLVMVER}-dev libmpc-dev libxt-dev graphviz doxygen dia gcc-avr gdb-avr avr-libc binutils-avr simulavr avrdude arduino libusbprog-dev sdcc sdcc-doc sdcc-libraries libcsfml-dev libglfw3-dev libgtk-3-dev gir1.2-gtksource-3.0 gobject-introspection libgirepository1.0-dev curl bison cabal-install libopencv-core-dev libopencv-imgproc-dev libopencv-calib3d-dev libopencv-ts-dev libopencv-features2d-dev libopencv-flann-dev libopencv-highgui-dev libopencv-ml-dev libopencv-objdetect-dev libopencv-photo-dev libopencv-video-dev libopencv-dev texinfo apt-transport-https ca-certificates curl gnupg-agent software-properties-common libsqlite3-dev

#
# Install Google Test environment for C++
#
RUN wget https://github.com/google/googletest/archive/release-1.7.0.zip && \
    unzip release-1.7.0.zip && \
    ( cd googletest-release-1.7.0 && \
    mkdir build && cd build && \
    cmake -DBUILD_SHARED_LIBS=ON .. && \
    make && \
    mkdir -p /usr/local && \
    cp -a ../include/gtest /usr/local/include && \
    cp -a lib* /usr/local/lib/ && \
    cd ../.. && rm -rf gtest* )

#
# Swift Installation
#
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q install -y \
    libatomic1 \
    libcurl4 \
    libxml2 \
    libedit2 \
    libsqlite3-0 \
    libc6-dev \
    binutils \
    libgcc-5-dev \
    libstdc++-5-dev \
    libpython2.7 \
    tzdata \
    git \
    pkg-config \
    && rm -r /var/lib/apt/lists/*

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# pub   4096R/ED3D1561 2019-03-22 [expires: 2021-03-21]
#       Key fingerprint = A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561
# uid                  Swift 5.x Release Signing Key <swift-infrastructure@swift.org
ARG SWIFT_SIGNING_KEY=A62AE125BBBFBB96A6E042EC925CC1CCED3D1561
ARG SWIFT_PLATFORM=ubuntu18.04
ARG SWIFT_BRANCH=swift-5.1.2-release
ARG SWIFT_VERSION=swift-5.1.2-RELEASE
ARG SWIFT_WEBROOT=https://swift.org/builds/

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY \
    SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION \
    SWIFT_WEBROOT=$SWIFT_WEBROOT

RUN set -e; \
    SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)/" \
    && SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz" \
    && SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
    # - Grab curl here so we cache better up above
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q update && apt-get -q install -y curl && rm -rf /var/lib/apt/lists/* \
    # - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
    && export GNUPGHOME="$(mktemp -d)" \
    && curl -fsSL "$SWIFT_BIN_URL" -o swift.tar.gz "$SWIFT_SIG_URL" -o swift.tar.gz.sig \
    && gpg --batch --quiet --keyserver ha.pool.sks-keyservers.net --recv-keys "$SWIFT_SIGNING_KEY" \
    && gpg --batch --verify swift.tar.gz.sig swift.tar.gz \
    # - Unpack the toolchain, set libs permissions, and clean up.
    && tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && chmod -R o+r /usr/lib/swift \
    && rm -rf "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz \
    && apt-get purge --auto-remove -y curl

#
# Install Jazzy
#
RUN gem install jazzy

#
# Install SourceKitten
#
RUN git clone https://github.com/jpsim/SourceKitten.git && \
    ( cd SourceKitten && swift build -c release && \
    mkdir -p /usr/local/bin && \
    cp -p .build/release/sourcekitten /usr/local/bin && \
    cp -p .build/release/sourcekitten `echo /var/lib/gems/*/gems/jazzy-*/bin/ | tr ' ' '\n' | tail -n1` )

# Add the official Java repository
RUN sudo add-apt-repository -y ppa:webupd8team/java
RUN sudo apt-get install -y openjdk-8-jre-headless

# Adding keys for ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# Installing ROS
RUN sudo apt-get update && sudo apt-get install -y ros-melodic-desktop-full \
		wget git nano
RUN rosdep init && rosdep update

RUN /bin/bash -c "echo 'export HOME=/home/ubuntu' >> /root/.bashrc && source /root/.bashrc"

# Creating ROS_WS
RUN mkdir -p ~/ros_ws/src

# Set up the workspace
RUN /bin/bash -c "source /opt/ros/melodic/setup.bash && \
                  cd ~/ros_ws/ && \
                  catkin_make && \
                  echo 'source ~/ros_ws/devel/setup.bash' >> ~/.bashrc && \
                  echo 'source ~/ros_ws/devel/setup.bash' >> /root/.bashrc "

RUN sudo apt install -y python-rosinstall python-rosinstall-generator python-wstool build-essential

# Updating ROSDEP and installing dependencies
##RUN cd ~/ros_ws && rosdep update && rosdep install --from-paths src --ignore-src --rosdistro=kinetic -y

# Sourcing
RUN /bin/bash -c "source /opt/ros/melodic/setup.bash && \
                  cd ~/ros_ws/ && rm -rf build devel && \
                  catkin_make"

# Print Installed Swift Version
RUN swift --version

