# rebased/repackaged base image that only updates existing packages
FROM mbentley/ubuntu:18.04
LABEL maintainer="Matt Bentley <mbentley@mbentley.net>"

# install omada controller (instructions taken from install.sh); then create a user & group and set the appropriate file system permissions
RUN \
  echo "**** Install Dependencies ****" &&\
  apt-get update &&\
  DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y gosu mongodb-server-core net-tools openjdk-8-jre-headless tzdata wget &&\
  rm -rf /var/lib/apt/lists/* &&\
  echo "**** Download Omada Controller ****" &&\
  cd /tmp &&\
  wget -nv "https://static.tp-link.com/2020/202007/20200714/Omada_SDN_Controller_v4.1.5_linux_x64.tar.gz" &&\
  echo "**** Extract and Install Omada Controller ****" &&\
  tar zxvf Omada_SDN_Controller_v4.1.5_linux_x64.tar.gz &&\
  rm Omada_SDN_Controller_v4.1.5_linux_x64.tar.gz &&\
  cd Omada_SDN_Controller_* &&\
  mkdir /opt/tplink/EAPController -vp &&\
  cp bin /opt/tplink/EAPController -r &&\
  cp data /opt/tplink/EAPController -r &&\
  cp properties /opt/tplink/EAPController -r &&\
  cp webapps /opt/tplink/EAPController -r &&\
  cp keystore /opt/tplink/EAPController -r &&\
  cp lib /opt/tplink/EAPController -r &&\
  cp install.sh /opt/tplink/EAPController -r &&\
  cp uninstall.sh /opt/tplink/EAPController -r &&\
  ln -sf "$(which mongod)" /opt/tplink/EAPController/bin/mongod &&\
  chmod 755 /opt/tplink/EAPController/bin/* &&\
  echo "**** Cleanup ****" &&\
  cd /tmp &&\
  rm -rf /tmp/Omada_SDN_Controller* &&\
  echo "**** Setup omada User Account ****" &&\
  groupadd -g 508 omada &&\
  useradd -u 508 -g 508 -d /opt/tplink/EAPController omada &&\
  mkdir /opt/tplink/EAPController/logs /opt/tplink/EAPController/work &&\
  chown -R omada:omada /opt/tplink/EAPController/data /opt/tplink/EAPController/logs /opt/tplink/EAPController/work

# patch log4j vulnerability
COPY log4j_patch.sh /log4j_patch.sh
RUN /log4j_patch.sh

COPY entrypoint-4.x.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 27001/udp 27002 29810/udp 29811 29812 29813
HEALTHCHECK --start-period=5m CMD /healthcheck.sh
VOLUME ["/opt/tplink/EAPController/data","/opt/tplink/EAPController/work","/opt/tplink/EAPController/logs"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-cp","/opt/tplink/EAPController/lib/*:","com.tplink.omada.start.OmadaLinuxMain"]
