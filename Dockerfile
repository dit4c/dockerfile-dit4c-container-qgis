FROM dit4c/dit4c-container-x11:xpra
MAINTAINER Tim Dettrick <t.dettrick@uq.edu.au>

RUN yum install -y \
  gcc gcc-c++ \
  cmake flex bison \
  libspatialite-devel spatialindex-devel \
  qtwebkit-devel qca2-devel qca-ossl qwtpolar-devel \
  qt-devel \
  proj-devel \
  sqlite-devel \
  qwt-devel \
  expat-devel \
  gsl-devel \
  gpsbabel \
  python-devel

RUN /usr/sbin/alternatives --set ld /usr/bin/ld.gold

RUN cd /tmp && SIP_VERSION=4.17 && \
  curl -s -L "http://sourceforge.net/projects/pyqt/files/sip/sip-$SIP_VERSION/sip-$SIP_VERSION.tar.gz" | tar xzv && \
  cd sip-$SIP_VERSION && \
  python configure.py && \
  make -j$(nproc) && \
  make install && \
  cd .. && \
  rm -rf sip-$SIP_VERSION

RUN cd /tmp && PYQT_VERSION=4.11.4 && \
  curl -s -L "http://sourceforge.net/projects/pyqt/files/PyQt4/PyQt-$PYQT_VERSION/PyQt-x11-gpl-$PYQT_VERSION.tar.gz" | tar xzv && \
  cd PyQt-x11-gpl-$PYQT_VERSION && \
  python configure-ng.py --qmake=/usr/lib64/qt4/bin/qmake --confirm-license && \
  make -j$(nproc) && \
  make install && \
  cd .. && \
  rm -rf PyQt-x11-gpl-$PYQT_VERSION

RUN cd /tmp && QSCINTILLA_VERSION=2.9.1 && \
  curl -s -L "http://sourceforge.net/projects/pyqt/files/QScintilla2/QScintilla-2.9.1/QScintilla-gpl-$QSCINTILLA_VERSION.tar.gz" | tar xzv && \
  cd QScintilla-gpl-$QSCINTILLA_VERSION && \
  cd Qt4Qt5 &&\
  /usr/lib64/qt4/bin/qmake qscintilla.pro && \
  make -j$(nproc) && \
  make install && \
  cd ../Python && \
  python configure.py --qmake=/usr/lib64/qt4/bin/qmake && \
  make -j$(nproc) && \
  make install && \
  cd .. && \
  rm -rf QScintilla-gpl-$QSCINTILLA_VERSION

RUN cd /tmp && \
  curl -s -L "http://download.osgeo.org/gdal/2.0.2/gdal-2.0.2.tar.gz" | tar xzv && \
  cd gdal* && \
  ./configure && make && make install && \
  rm -r gdal*

RUN yum install -y libtiff-devel libpng-devel fftw-devel cairo-devel \
  readline-devel netcdf-devel geos-devel blas-devel lapack-devel \
  postgresql-devel

RUN pip install --upgrade pip && \
  export C_INCLUDE_PATH=/usr/include/gdal && \
  export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH && \
  pip install numpy GDAL psycopg2

RUN cd /tmp && \
  curl -s -L "https://grass.osgeo.org/grass70/source/grass-7.0.2.tar.gz" | tar xzv && \
  cd grass* && \
  ./configure \
    --prefix=/opt \
    --enable-64bit \
    --with-libs=/usr/lib64 \
    --with-blas \
    --with-gdal=/usr/local/bin/gdal-config \
    --with-proj \
    --with-fftw \
    --with-geos \
    --with-netcdf \
    --with-pthread \
    --with-readline \
    --with-sqlite \
    --with-freetype-includes=/usr/include/freetype2 && \
  LD_LIBRARY_PATH=/usr/local/lib make && make install && \
  ln -s /opt/grass* /opt/grass && \
  rm -r grass*

RUN echo "/usr/lib64/libpng.so" > /etc/ld.so.preload

RUN cd /opt && \
  curl -s -L "https://github.com/qgis/QGIS/archive/final-2_12_3.tar.gz" | tar xzv && \
  cd QGIS* && \
  mkdir build && \
  cd build && \
  cmake -DGRASS_PREFIX=/opt/grass -DCMAKE_INSTALL_PREFIX=/opt/qgis -DWITH_INTERNAL_QWTPOLAR=false .. && \
  make -j$(nproc) all install && \
  ln -s /opt/qgis/bin/qgis /usr/bin/qgis && \
  ln -s /opt/qgis/bin/qbrowser /usr/bin/qbrowser && \
  cd /opt/QGIS* && \
  QGISDIR=$(pwd) && \
  install -o root -g root -m 644 ${QGISDIR}/debian/qgis.desktop /usr/share/applications/qgis.desktop && \
  install -o root -g root -m 644 ${QGISDIR}/debian/qbrowser.desktop /usr/share/applications/qbrowser.desktop && \
  # Install application icon
  for size in 16x16 22x22 24x24 32x32 36x36 48x48 64x64 72x72 96x96 128x128 192x192 256x256; do \
    install -o root -g root -m 644 ${QGISDIR}/debian/qgis-icon${size}.png /usr/share/icons/hicolor/${size}/apps/qgis.png ; \
    install -o root -g root -m 644 ${QGISDIR}/debian/qbrowser-icon${size}.png /usr/share/icons/hicolor/${size}/apps/qbrowser.png ; \
  done && \
  cd /opt && \
  rm -rf $QGISDIR

RUN LNUM=$(sed -n '/launcher_item_app/=' /etc/tint2/panel.tint2rc | head -1) && \
  sed -i "${LNUM}ilauncher_item_app = /usr/share/applications/qbrowser.desktop" /etc/tint2/panel.tint2rc && \
  sed -i "${LNUM}ilauncher_item_app = /usr/share/applications/qgis.desktop" /etc/tint2/panel.tint2rc && \
  rm /usr/share/applications/qt4-*.desktop

RUN pip install ipython jupyter

COPY etc /etc
COPY var /var

# Update dynamic library paths using /etc/ld.so.conf.d
RUN ldconfig
RUN su - researcher -c "mkdir -p ~/.jupyter && echo \"c.NotebookApp.base_url = '/jupyter'\" > ~/.jupyter/jupyter_notebook_config.py"
