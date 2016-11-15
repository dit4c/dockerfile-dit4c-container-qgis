FROM dit4c/dit4c-container-x11:debian
MAINTAINER Tim Dettrick <t.dettrick@uq.edu.au>

# Ensure we can handle HTTPS apt sources
RUN apt-get update && apt-get install -y apt-transport-https && apt-get clean

# Install QGIS, Python, R & RStudio
RUN echo "deb http://qgis.org/debian/ jessie main" >> /etc/apt/sources.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-key 073D307A618E5811 && \
  echo "deb https://cran.csiro.au/bin/linux/debian jessie-cran3/" >> /etc/apt/sources.list && \
  apt-key adv --keyserver keys.gnupg.net --recv-key 381BA480 && \
  apt-get update && \
  apt-get install -y \
    qgis python-pip python-all-dev gdebi-core r-base r-base-dev \
    libcurl4-gnutls-dev libxml2-dev libssl-dev pkg-config libgdal-dev \
    libproj-dev libssh2-1-dev && \
  export PKG=rstudio-server-0.99.893-amd64.deb && \
  cd /tmp && \
  curl -LOs https://download2.rstudio.org/$PKG && \
  gdebi --non-interactive $PKG && \
  rm $PKG && \
  apt-get clean

# Install Jupyter
RUN pip install ipython jupyter

# Install R kernel for Jupyter
RUN Rscript -e \
  " options(repos=structure(c(CRAN='https://cran.csiro.au'))); \
    install.packages(c('repr', 'IRdisplay', 'evaluate', 'crayon', 'pbdZMQ', 'devtools', 'uuid', 'digest')); \
    devtools::install_github('IRkernel/IRkernel'); \
    IRkernel::installspec(user = FALSE)"

# Install RQGIS and other useful libraries
RUN Rscript -e \
  " options(repos=structure(c(CRAN='https://cran.csiro.au'))); \
    install.packages(c('raster', 'RQGIS'), dependencies = TRUE)"

RUN LNUM=$(sed -n '/launcher_item_app/=' /etc/tint2/panel.tint2rc | head -1) && \
  sed -i "${LNUM}ilauncher_item_app = /usr/share/applications/qbrowser.desktop" /etc/tint2/panel.tint2rc && \
  sed -i "${LNUM}ilauncher_item_app = /usr/share/applications/qgis.desktop" /etc/tint2/panel.tint2rc

COPY etc /etc
COPY var /var

# Create Jupyter config
RUN su - researcher -c "mkdir -p ~/.jupyter && printf \"c.NotebookApp.base_url = '/jupyter'\nc.NotebookApp.port = 8889\n\" > ~/.jupyter/jupyter_notebook_config.py"

# Create R user lib directory
RUN su - researcher -c "Rscript -e \"cat(system(paste('eval', 'echo', Sys.getenv('R_LIBS_USER'), sep=' '), intern=TRUE))\" | xargs mkdir -p"
