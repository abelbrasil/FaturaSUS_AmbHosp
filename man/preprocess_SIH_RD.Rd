% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/4_2_preprocess_SIH_RD.R
\name{preprocess_SIH_RD}
\alias{preprocess_SIH_RD}
\title{Returns Reduced Data (RD) by SIH-AIH in a structured and filtered way.}
\usage{
preprocess_SIH_RD(
  cid,
  raw_SIH_RD,
  county_id,
  procedure_details,
  health_establishment_id
)
}
\arguments{
\item{cid}{É a tabela retornada pela função \code{get_details} quando o parâmetro \code{detail_name='CID'}}

\item{raw_SIH_RD}{Dados de Autorização de Internação Hospitalar (AIH) Reduzida (RD) do Sistema de Informação Hospitalar (SIH)}

\item{county_id}{string ou vetor de strings. Código do Município de Atendimento.}

\item{procedure_details}{São os dados retornados pelo funcão \code{get_procedure_details}}

\item{health_establishment_id}{string ou vetor de strings. Código do estabelecimento de saúde.}
}
\value{
Retorna a tabela da Autorização de Internação Hospitalar (AIH) Reduzida (RD) já filtrada e tratada.
}
\description{
Estrutura e filtra os dados da Autorização de Internação Hospitalar (AIH) Reduzida (RD) e combina as informações do CNES, SIGTAP e da base de dados \code{counties}.
}
