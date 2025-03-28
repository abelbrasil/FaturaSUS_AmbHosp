% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/list_SIA_SIH_files.R
\name{list_SIA_SIH_files}
\alias{list_SIA_SIH_files}
\title{Returns the names of the DBC files that need to be downloaded.}
\usage{
list_SIA_SIH_files(
  data_source,
  data_type,
  state_abbr,
  publication_date_start,
  publication_date_end
)
}
\arguments{
\item{data_source}{String. Valores aceitos "SIA", "SIH"}

\item{data_type}{String. Valores aceitos "PA", "RD", "RJ", "SP"}

\item{state_abbr}{String. Sigla da Unidade Federativa}

\item{publication_date_start}{Uma string no formato "AAAA-MM-01", indicando o mes de inicio para o download dos dados.}

\item{publication_date_end}{Uma string no formato "AAAA-MM-01", indicando o mes de termino para o download dos dados.}
}
\value{
dir_files. Um DataFrame contendo o nome do arquivo, a data associada ao arquivo, a UF (Unidade Federativa) do arquivo e o tipo do arquivo (PA, RD, RJ ou SP).
}
\description{
A função retorna um DataFrame com os nomes dos arquivos (PA, RD, RJ ou SP) para cada mês que precisam ser baixados.
}
\examples{
\dontrun{
  list_SIA_SIH_files(
    data_source = "SIA",
    data_type = "PA",
    state_abbr = "CE",
    publication_date_start = "2023-01-01",
    publication_date_end = "2023-03-01"
  )
}

}
