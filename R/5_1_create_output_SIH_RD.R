
#' Create a database for the Hospital Information System (SIH/SUS) - AIH-RD
#'
#' @description Processar arquivos de Autorização de Internação Hospitalar (AIH) Reduzida (RD) do Sistema de Informação Hospitalar (SIH) do DATASUS e integrá-los com dados do CNES e SIGTAP.
#'
#' @param year_start numeric. Ano inicial para o download dos dados, no formato yyyy.
#' @param month_start numeric. Mês inicial para o download dos dados, no formato mm.
#' @param year_end numeric. Ano final para o download dos dados, no formato yyyy.
#' @param month_end numeric. Mês final para o download dos dados, no formato mm.
#' @param state_abbr string ou vetor de strings. Sigla da Unidade Federativa
#' @param county_id string ou vetor de strings. Código do município de atendimento. O padrão é NULL.  Se informado, todos os estabelecimentos de saúde desse município serão filtrados. Este parâmetro é obrigatório se health_establishment_id for NULL.
#' @param health_establishment_id string ou vetor de strings. Código do estabelecimento de saúde. O padrão é NULL. Este parâmetro é obrigatório se county_id for NULL. Será desconsiderado se county_id contiver um código válido de município.
#' @param save_csv Lógico. O valor padrão é TRUE. Quando definido como TRUE, a base de dados resultante da função é salva como um arquivo CSV no diretório './data-raw'.
#'
#' @return Um DataFrame estruturado contendo dados do SUS-SIH-AIH-RD, filtrados por estado ou estabelecimentos de saúde dentro de um intervalo de datas específico, e combinado com informações do CNES e SIGTAP. A função retorna um objeto como os dados e salva a base de dados na pasta './data-raw' em formato CSV, com o nome 'outputSIH_RD.csv'.
#'
#' @examples
#'   \dontrun{
#'     dados = create_output_SIH_RD(
#'       year_start = 2023,
#'       month_start = 1,
#'       year_end = 2023,
#'       month_end = 3,
#'       state_abbr = "CE",
#'       county_id = NULL,
#'       health_establishment_id = c("2561492", "2481286"),
#'       save_csv = TRUE
#'     )
#'  }
#' @export
#'
create_output_SIH_RD <-
  function(year_start,
           month_start,
           year_end,
           month_end,
           state_abbr,
           county_id = NULL,
           health_establishment_id = NULL,
           save_csv = TRUE) {
    tempo_inicio <- system.time({

      # AIH = Autorização de Internação Hospitalar
      # RD = Reduzida(Aprovada)

      `%>%` <- dplyr::`%>%`
      information_system = 'SIH-RD'

      #Se o id do municipio for igual a 7 caracteres, remove o último caracter.
      county_id = process_county_id(county_id)

      state_abbr = toupper(trimws(state_abbr))

      #Cria uma variável global com os dados do município
      get_counties()

      #Baixa os dados do CNES/ST e descompacta os dados do CNES/CADGER
      get_CNES()

      download_sigtap_files(year_start,
                            month_start,
                            year_end,
                            month_end,
                            newer = FALSE)

      publication_date_start <- lubridate::ym(stringr::str_glue("{year_start}-{month_start}"))
      publication_date_end <- lubridate::ym(stringr::str_glue("{year_end}-{month_end}"))

      #Ler os dados do SIGTAP (Procedimentos e CID)
      procedure_details <- get_procedure_details()
      cid <- get_detail("CID") %>%
        dplyr::mutate(
          #NO_CID = iconv(NO_CID, "latin1", "UTF-8"),
          dplyr::across(dplyr::ends_with("CID"), stringr::str_trim),
          NO_CID = stringr::str_c(CO_CID, NO_CID, sep = "-")
        )


      tmp_dir <- tempdir()
      information_system_dir <- stringr::str_glue("{tmp_dir}\\{information_system}")

      #Verificar se a pasta 'tempdir()/SIH-RD' já existe, se sim, apaga os arquivos que estão dentro dela
      if (!dir.exists(information_system_dir)) {
        dir.create(information_system_dir)
      } else{
        arquivos <- list.files(information_system_dir, full.names = TRUE)
        unlink(arquivos, recursive = TRUE)
      }

      #Lista os nomes dos arquivos RD que serão baixados de cada mês
      dir_files = list_SIA_SIH_files(information_system, data_type = "RD",
                                     state_abbr,
                                     publication_date_start,
                                     publication_date_end)

      #Verifica se dir_files contém o nome de pelo menos um arquivo RD para cada mês.
      check_file_list(dir_files,
                      "RD",
                      state_abbr,
                      publication_date_start,
                      publication_date_end)

      #Separa os arquivos RD em grupos, caso haja vários arquivos para serem baixados.
      files_chunks = chunk(dir_files$file_name)
      n_chunks = length(files_chunks)

      data_source = stringr::str_sub(information_system, 1, 3)
      base_url <- stringr::str_glue(
        "ftp://ftp.datasus.gov.br/dissemin/publicos/{data_source}SUS/200801_/Dados/")
      rm(dir_files)

      for (n in 1:n_chunks) {
        dir.create(stringr::str_glue("{tmp_dir}\\{information_system}\\chunk_{n}"))
        download_files_url <- stringr::str_glue("{base_url}{files_chunks[[n]]}")
        output_files_path <- stringr::str_glue("{tmp_dir}\\{information_system}\\{names(files_chunks)[n]}\\{files_chunks[[n]]}")

        #Download dos dados RD
        purrr::walk2(download_files_url, output_files_path, curl::curl_download)

        #Carrega os dados RD
        raw_SIH_RD <- purrr::map_dfr(output_files_path, read.dbc::read.dbc, as.is=TRUE, .id="file_id")

        #Retorna TRUE se o DF raw_SIH_RD contiver valores correspondente ao
        # município especificado (county_id)
        county_TRUE <- !is.null(county_id) && any(county_id %in% raw_SIH_RD$MUNIC_MOV)

        #Retorna TRUE se o DF raw_SIH_RD contiver valores correspondente ao
        # estabelecimento especificado (health_establishment_id)
        establishment_TRUE <- !is.null(health_establishment_id) &&
          any(health_establishment_id %in% raw_SIH_RD$CNES)

        #Filtra, Estrutura, une e cria novas colunas nos dados SP.
        if(county_TRUE){
          #Filtra todos os estabelecimentos do municipio county_id
          output <- preprocess_SIH_RD(cid,
                                      raw_SIH_RD,
                                      county_id,
                                      procedure_details,
                                      health_establishment_id = NULL)

        }  else if (establishment_TRUE){
          #Filtra só os estabelecimentos health_establishment_id
          output <- preprocess_SIH_RD(cid,
                                      raw_SIH_RD,
                                      county_id = NULL,
                                      procedure_details,
                                      health_establishment_id)
        } else if (is.null(county_id) & is.null(health_establishment_id)) {
          #Filtra todos os estabelecimentos do(s) estado(s) state_abbr
          output <- preprocess_SIH_RD(cid,
                                      raw_SIH_RD,
                                      county_id,
                                      procedure_details,
                                      health_establishment_id)
        } else {
          output = NULL
        }
        rm(raw_SIH_RD)
        #O output de cada chunk é salvo em um arquivo .rds em uma pasta temporária do sistema.
        if (!is.null(output)) {
          output_path <-
            stringr::str_glue(
              "{tmp_dir}\\{information_system}\\{names(files_chunks)[n]}\\output{information_system}_chunk_{n}.rds")

          saveRDS(output, file = output_path)
        }
        rm(output)
      }
      rm(cid,procedure_details)
      rm("counties", envir = .GlobalEnv)
      rm("health_establishment", envir = .GlobalEnv)

      #Une os arquivos output.rds de cada chunk em um único arquivo.
      outputSIH_RD <-
        tempdir() %>%
        list.files(information_system,
                   full.names = TRUE,
                   recursive = TRUE) %>%
        purrr::keep(~ stringr::str_detect(.x, "\\.rds$")) %>%
        purrr::map_dfr(readRDS)

      if(any(is.na(outputSIH_RD$`Procedimentos realizados`))){
        procedure_revoked = unique(
          outputSIH_RD$`CO Procedimentos realizados`[is.na(outputSIH_RD$`Procedimentos realizados`)]
        )

        warning(paste('A coluna "Procedimentos realizados" e suas colunas relacionadas apresentam valores nulos, provavelmente porque o(s) procedimento(s)', paste(procedure_revoked,collapse = ", "), 'foi/foram revogado(s). Para obter esses valores, utilize a função procedure_revoked(), passando como parâmetro a saida da função create_output_SIH_RD()\n'))
      }

      # Salva o data frame em arquivo CSV no diretorio atual
      if (nrow(outputSIH_RD) == 0 | ncol(outputSIH_RD) == 0){
        cat("As bases de dados SIH/RD não contêm valores para o município ou estabelecimentos informados.\n")
      } else {
        if (save_csv){
          write.csv2(outputSIH_RD,
                     "./data-raw/outputSIH_RD.csv",
                     na = "",
                     row.names = FALSE)
        }
      }

    })
    cat("Tempo de execução:", tempo_inicio[3] / 60, "minutos\n")
    return(outputSIH_RD)
  }
