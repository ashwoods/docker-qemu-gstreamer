ARG BASE=python:3.6
FROM ${BASE} as base
ARG QEMU_ARCH=x86_64
COPY qemu-${QEMU_ARCH}-static /usr/bin/

ARG PREFIX='/usr/local'
# ARG GST_VERSION=1.14.1
ARG SRC='/usr/local/src'
ARG PY_MAJOR_MINOR=3.6
# -- START BASE -- #

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHON=/usr/local/bin/python${PY_MAJOR_MINOR}
ENV CPPFLAGS="-I/usr/local/include/python${PY_MAJOR_MINOR}m"
ENV PYGOBJECT_CFLAGS='-I/usr/local/include/pygobject-3.0 -I/usr/include/pygobject-3.0 -I/usr/include/glib-2.0 -I/usr/lib/aarch64-linux-gnu/glib-2.0/include'
ENV PYGOBJECT_LIBS='-lgobject-2.0 -lglib-2.0'
ENV LD_LIBRARY_PATH=${PREFIX}
ENV PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
ENV PATH=${PREFIX}/bin:${PATH}  
ENV GI_TYPELIB_PATH=${PREFIX}/share/gir-1.0:${PREFIX}/lib/girepository-1.0

RUN set -ex && env

# base and common tools
RUN set -ex \
    && apt-get -yqq update \
    && apt-get install -yq \ 
        apt-utils \
		curl \
		git \
		locales \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/*

RUN set -ex \
	&& buildDeps=' \
		software-properties-common \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y gcc-6 g++-6 \
	&& update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-6 10 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 10 \
	&& apt-get purge -y --auto-remove $buildDep


WORKDIR ${SRC}

RUN set -ex && for module in gstreamer gst-python gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly; do \
  		git clone git://anongit.freedesktop.org/git/gstreamer/$module ; \
	done

RUN curl https://freedesktop.org/software/pulseaudio/webrtc-audio-processing/webrtc-audio-processing-0.3.tar.xz| tar -Jx
RUN curl https://nice.freedesktop.org/releases/libnice-0.1.14.tar.gz | tar -zx

RUN set -ex \
	&& buildDeps=' \
		automake \
		autopoint \
		autotools-dev \
		bison \
		yasm \
		build-essential \
		gobject-introspection \
		cmake \
		dpkg-dev \
		flex \
		libtool \
		gettext \
		libgirepository1.0-dev \
		libasound2-dev \
		libavcodec-dev \
		libbz2-dev \
		libcrypto++-dev \
		libfaad-dev \
		libgnutls28-dev \
		libgupnp-igd-1.0-dev \
		libjack-jackd2-dev \
		libmad0-dev \
		libogg-dev \
		libopus-dev \
		libpulse-dev \
		libsoup2.4-dev \
		libsrtp-dev \
		libssl-dev \
		libtheora-dev \
		libv4l-dev \
		libvorbis-dev \
		libvpx-dev \
		libx264-dev \
		libxv-dev \
     	libavutil-dev \
 		libcairo-dev \
		libavfilter-dev \
 		libavformat-dev \
 		libjson-glib-dev \
		liborc-dev \
	' \
	&& sed -i -- 's/# deb-src/deb-src/g' /etc/apt/sources.list \
	&& apt-get update && apt-get install -yq $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& apt-get clean \
	&& rm -rf /tmp/* /var/tmp/*

# libfaac-dev \ Check if we need this

RUN set -ex && pip install pycairo 
RUN set -ex && pip install pygobject

WORKDIR ${SRC}/gstreamer
RUN set -ex && \
	./autogen.sh --disable-gtk-doc --prefix=${PREFIX} --disable-examples --enable-introspection \
	&& make -j$(nproc) \
	&& make install \
    && ldconfig 

WORKDIR ${SRC}/webrtc-audio-processing-0.3
RUN ./configure --prefix=${PREFIX}  \
	&& make -j$(nproc) \
	&& make install \
    && ldconfig 

WORKDIR ${SRC}/libnice-0.1.14
RUN ./configure --prefix=${PREFIX} --enable-introspection \
	&& make -j$(nproc) \
	&& make install \
    && ldconfig 

WORKDIR ${SRC}/gst-plugins-base
RUN set -ex && \
	./autogen.sh --disable-gtk-doc --prefix=${PREFIX} --enable-introspection  \
	&& make -j$(nproc) \
	&& make install \
    && ldconfig

WORKDIR ${SRC}/gst-plugins-good
RUN set -ex && \
	./autogen.sh --disable-gtk-doc --prefix=${PREFIX} --enable-introspection \
	&& make -j$(nproc) \
	&& make install \
    && ldconfig 

WORKDIR ${SRC}/gst-plugins-ugly
RUN set -ex && \
	./autogen.sh --disable-gtk-doc --prefix=${PREFIX} --enable-introspection \
	&& make -j$(nproc) \
	&& make install \
    && ldconfig 

WORKDIR ${SRC}/gst-plugins-bad
RUN set -ex && \
	./autogen.sh --disable-gtk-doc --prefix=${PREFIX} --enable-introspection  \
	&& make -j$(nproc) \
	&& make install \
    && ldconfig 

# WORKDIR ${SRC}/gst-libav
# RUN set -ex && \
#  	./autogen.sh --disable-gtk-doc --prefix=${PREFIX} --enable-introspection  \
#  	&& make -j$(nproc) \
#  	&& make install \
#     && ldconfig 

WORKDIR ${SRC}/gst-python
RUN set -ex && \
       ./autogen.sh --disable-gtk-doc --prefix=${PREFIX} --enable-introspection \
        && make -j$(nproc) \
 	&& make install \
    && ldconfig  

RUN pip install --upgrade --no-deps --force-reinstall pygobject




