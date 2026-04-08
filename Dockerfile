FROM rocker/r2u:jammy

LABEL org.opencontainers.image.authors="Lise Vaudor <lise.vaudor@ens-lyon.fr>, Samuel Dunesme <samuel.dunesme@ens-lyon.fr>"
LABEL org.opencontainers.image.source="https://github.com/lvaudor/learnr_tests_stats_exos"
LABEL org.opencontainers.image.description="Deck d'exercices sur les tests statistiques avec R."

RUN locale-gen fr_FR.UTF-8

RUN Rscript -e 'install.packages("shiny")'
RUN Rscript -e 'install.packages("learnr")'
RUN Rscript -e 'install.packages("dplyr")'
RUN Rscript -e 'install.packages("tibble")'
RUN Rscript -e 'install.packages("ggplot2")'
RUN Rscript -e 'install.packages("purrr")'
RUN Rscript -e 'install.packages("gridExtra")'
RUN Rscript -e 'install.packages("gganimate")'
RUN Rscript -e 'install.packages("infer")'
RUN Rscript -e 'install.packages("DiagrammeR")'


# On copie l'arborescence de fichiers dans un dossier app à la racine de l'image. Ce sera le working directory des containers lancés avec notre image
RUN mkdir /app
ADD . /app
WORKDIR /app

RUN R -e 'remotes::install_local()'

EXPOSE 3840

RUN groupadd -g 1010 app && useradd -c 'app' -u 1010 -g 1010 -m -d /home/app -s /sbin/nologin app
USER app

CMD  ["R", "-f", "app.R"]
