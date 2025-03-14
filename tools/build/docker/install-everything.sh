#!/bin/sh

#Just do everything
apk update
apk add perl perl-io-socket-ssl perl-dev redis libarchive-dev libbz2 openssl-dev zlib-dev
apk add imagemagick imagemagick-perlmagick libwebp-tools libheif
apk add g++ make pkgconf gnupg wget curl nodejs nodejs-npm file
apk add shadow s6 s6-portable-utils

#Hey it's cpanm
curl -L https://cpanmin.us | perl - App::cpanminus

#Alpine's libffi build comes with AVX instructions enabled
#Rebuild our own libffi with those disabled
if [ $(uname -m) == 'x86_64' ]; then
  #Install deps only
  cpanm --notest --installdeps Alien::FFI
  curl -L -s https://cpan.metacpan.org/authors/id/P/PL/PLICEASE/Alien-FFI-0.25.tar.gz | tar -xz
  cd Alien-FFI-0.25
  #Patch build script to disable AVX
  sed -i 's/--disable-builddir/--disable-builddir --with-gcc-arch=x86-64-v2/' alienfile
  perl Makefile.PL && make install
  cd ../ && rm -rf Alien-FFI-0.25
fi

#Install the LRR dependencies proper
cd tools && cpanm --notest --installdeps . -M https://cpan.metacpan.org && cd ..
npm run lanraragi-installer install-full

#Cleanup to lighten the image
apk del perl-dev g++ make gnupg wget curl nodejs nodejs-npm openssl-dev file
rm -rf /root/.cpanm/* /root/.npm/ /usr/local/share/man/* node_modules /var/cache/apk/*
