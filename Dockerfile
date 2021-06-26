FROM ubuntu:latest AS sdk
RUN apt-get update && apt-get install -y \
	git \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/osxcross &&                                      \
    cd /opt &&                                                  \
    git clone https://github.com/tpoechtrager/osxcross.git &&   \
    cd osxcross 

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
	clang \
	make \
	libssl-dev \
	lzma-dev \
	libxml2-dev \
	&& rm -rf /var/lib/apt/lists/*
	
ARG SDK_TOOLS=Command_Line_Tools_macOS_10.13_for_Xcode_9.4.1.dmg
ARG CLIB_TOOLS=Command_Line_Tools_macOS_10.13_for_Xcode_10.dmg
COPY ${SDK_TOOLS} /home/
COPY ${CLIB_TOOLS} /home/
 

RUN apt-get update && apt-get install -y \
	cmake \
	cpio \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
	liblzma-dev \
	libbz2-dev \
	&& rm -rf /var/lib/apt/lists/*
	
COPY gen_sdk_package_tools_dmg.sh /opt/osxcross/tools
	
WORKDIR /opt/osxcross
RUN ./tools/gen_sdk_package_tools_dmg.sh "/home/${SDK_TOOLS}"
RUN ./tools/gen_sdk_package_tools_dmg.sh "/home/${CLIB_TOOLS}"
RUN mkdir tmp2
RUN tar -xf MacOSX10.14.sdk.tar.xz -C tmp2 MacOSX10.14.sdk/usr/include/c++/
RUN mv tmp2/MacOSX10.14.sdk tmp2/MacOSX10.13.sdk
RUN xz -d  MacOSX10.13.sdk.tar.xz
RUN cd tmp2 && tar rf ../MacOSX10.13.sdk.tar .
RUN xz -z MacOSX10.13.sdk.tar
RUN mv MacOSX10.13.sdk.tar.xz tarballs/

ENV UNATTENDED=1 
RUN ./build.sh

FROM ubuntu:latest as final
COPY --from=sdk /opt/osxcross/target /usr/osxcross  
COPY --from=sdk /opt/osxcross/tools /usr/osxcross/tools
