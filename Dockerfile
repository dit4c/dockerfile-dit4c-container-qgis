FROM dit4c/dit4c-container-x11
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
  rm -r grass*

RUN cd /opt && \
  curl -s -L "https://github.com/qgis/QGIS/archive/final-2_12_3.tar.gz" | tar xzv && \
  cd QGIS* && \
  mkdir build && \
  cd build && \
  cmake -D WITH_INTERNAL_QWTPOLAR=false .. && \
  make -j$(nproc)

RUN echo "/usr/lib64/libpng.so" > /etc/ld.so.preload
