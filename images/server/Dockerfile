# The "server" every Linux and networking lab runs on: Rocky Linux 9 with real systemd.
ARG BASE=rockylinux/rockylinux:9.8
FROM ${BASE}

RUN dnf -y install \
      systemd procps-ng iproute iputils lsof psmisc findutils util-linux less \
      vim-minimal nano nginx openssh-server openssh-clients cronie logrotate \
      python3 sudo nftables bind-utils tar hostname ncurses which diffutils \
    && dnf clean all && rm -rf /var/cache/dnf

# Units that only make sense on real hardware; masking them keeps boot quiet.
RUN systemctl mask \
      systemd-udevd.service systemd-udevd-kernel.socket systemd-udevd-control.socket \
      systemd-modules-load.service sys-kernel-debug.mount sys-kernel-tracing.mount \
      sys-kernel-config.mount dev-hugepages.mount systemd-firstboot.service \
      getty.target console-getty.service systemd-logind.service \
      dnf-makecache.timer nginx.service sshd.service \
    && systemctl set-default multi-user.target \
    && systemctl unmask nginx.service sshd.service \
    && systemctl disable nginx.service sshd.service 2>/dev/null || true

ENV container=docker
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
