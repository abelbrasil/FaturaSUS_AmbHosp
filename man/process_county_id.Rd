% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/process_county_id.R
\name{process_county_id}
\alias{process_county_id}
\title{Removes the last character from county_id if it is 7 characters long.}
\usage{
process_county_id(county_id)
}
\arguments{
\item{county_id}{string ou vetor de strings. Código do Município de Atendimento.}
}
\value{
Retorna o \code{county_id} com um caractere a menos se ele tiver 7 caracteres.
}
\description{
Removes the last character from county_id if it is 7 characters long.
}
