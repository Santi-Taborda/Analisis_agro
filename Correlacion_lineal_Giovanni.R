#Libraries
library(bdrc)
library(ggplot2)
library(stringr)
library(lubridate)
library(data.table)
library(readxl)
library(officer)
library(flextable)
library(tidyverse)
library(dplyr)
library(gridExtra)
library(grid)
library(rlang)
library(scales)

#Folder to save documents C:\Users\giral\OneDrive\Documentos\EIS\Python\Analisis_agro\Temperaturas_Mapa_Totui.csv
setwd("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro")

#AFOROS_TOTAL = read.csv2("C:/Users/giral/OneDrive/Documentos/EIS/SAT/RESUMEN_AFOROS_SAT.csv")


#PARA AYA con sensor
AFOROS_TOTAL = read.csv2("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Temperaturas_Mapa_Totui.csv", sep = ",")

#AFOROS_TOTAL = read.csv2("C:/Users/giral/OneDrive/Documentos/EIS/Aguas_operación/RESUMEN_AYA.csv")

AFOROS_TOTAL$Temperatura_totui=as.numeric(AFOROS_TOTAL$Temperatura_totui)
AFOROS_TOTAL$Temperatura_rio_mapa=as.numeric(AFOROS_TOTAL$Temperatura_rio_mapa)

for (i in 1) { 
  i=1
  #Creates a data frame only with the data of the place
  DATOS = AFOROS_TOTAL
  names(DATOS)
  
  AFOROS2 = DATOS
  names(AFOROS2) = c("Fecha", "MAPA", "TOTUI")
  AFOROS2 = na.omit(AFOROS2)
  
  AFOROS_TABLA <- AFOROS2[-nrow(AFOROS2), ]
  
  plot(AFOROS_TABLA$MAPA, AFOROS_TABLA$TOTUI)
  AFOROS = AFOROS2[,c("MAPA", "TOTUI")]
  
  h_desborde=max(AFOROS$MAPA)+(max(AFOROS$TOTUI)*0.3)
  
  Datos_Curva_Gasto = plot_instr(code = {
    par(new = FALSE, mar = c(5.5, 5, 5, 5))
    plot(
      AFOROS_TABLA$MAPA,
      AFOROS_TABLA$TOTUI,
      main = "Datos de aforos usados para curva de gasto",
      xlab = "Altura lámina de agua, h (m)",
      ylab = "Caudal (m^3/s)",
    )
    grid(
      nx=NULL,
      ny=NULL,
      lty=2,
      col="gray",
      lwd=1
    )
    
  })
  
  
  set.seed(1)
  
  
  
  # GPLM <- gplm(Q ~ W, AFOROS)
  # GPLM$WAIC
  # autoplot(GPLM)
  # PLM <- plm(Q ~ W, AFOROS)
  # PLM$WAIC
  # PLM0 <- plm0(Q ~ W, AFOROS) 
  # PLM0$WAIC
  # GPLM0 <- gplm0(Q ~ W, AFOROS)
  # GPLM0$WAIC
  # t_obj <- plm0(Q ~ W, AFOROS,h_max = h_desborde, num_cores = 4 ) 
  # MODELO.fit <- plm0(Q ~ W, AFOROS,h_max = h_desborde, num_cores = 4 )
  # modelo <- "plm0
  
  
  
  
  
  # Takes the discharge and water elevation for data frame AROFOS
  t_obj <- tournament(formula = TOTUI ~ MAPA, data = AFOROS) 
  
  Torneo=autoplot(t_obj) #Save the tourment results image to printing in report
  Resumen = as.data.frame(summary(t_obj)) #Creates a data frame with the resume data of Tournament
  print(t_obj) #Prints the winner of the tourment
  modelo = unique(Resumen[which(Resumen$winner == "TRUE" & #Saves the name of the tournament winner
                                  Resumen$round == 2), "model"])
  CURVA <- function(AFOROS, modelo) {
    switch(
      modelo,
      gplm0 = {
        MODELO.fit <- gplm0(Q ~ W,
                            data = AFOROS,
                            h_max = h_desborde,
                            num_cores = 4)
      },
      gplm = {
        MODELO.fit <- gplm(Q ~ W,
                           data = AFOROS,
                           h_max = h_desborde,
                           num_cores = 4)
      },
      plm = {
        MODELO.fit <- plm(Q ~ W,
                          data = AFOROS,
                          h_max = h_desborde,
                          num_cores = 4)
      },
      plm0 = {
        MODELO.fit <- plm0(Q ~ W,
                           data = AFOROS,
                           h_max = h_desborde,
                           num_cores = 4)
      }
    )
    return(MODELO.fit)
  }
  
  #Creates a variable with the discharge in function of the water level using the winner model
  MODELO.fit = CURVA(AFOROS, modelo) 
  
  Grafico = autoplot(MODELO.fit, type = "rating_curve") #Saves the plot of the rating curve
  Curva_Gasto_1 = autoplot(MODELO.fit, transformed = TRUE) #Saves the plot of the logaritmic curve
  summary(MODELO.fit) #Resumes the data obteined in fitting 
  #OTHER PLOTTING OPTIONS FOR FITTING RESULTS:
  
  #autoplot(MODELO.fit,type='histogram',param='a')
  # autoplot(MODELO.fit,type='histogram',param='b')
  # autoplot(MODELO.fit,type='histogram',param='c',transformed=TRUE)
  # autoplot(MODELO.fit,type='histogram',param='hyperparameters')
  # autoplot(MODELO.fit,type='histogram',param='latent_parameters')
  # autoplot(MODELO.fit,type='residuals')
  # autoplot(MODELO.fit,type='f')
  # autoplot(MODELO.fit,type='sigma_eps')
  
  minimo=min(AFOROS_TABLA$W)-(min(AFOROS_TABLA$W)*0.2)
  maximo=max(AFOROS_TABLA$W)+(max(AFOROS_TABLA$W)*0.2)
  
  CAUDALES = predict(MODELO.fit, newdata = seq(0, h_desborde, 0.1))
  CAUDALES_tabla = predict(MODELO.fit, newdata = seq(minimo, maximo, (maximo-minimo)/10))
  PARAMETROS = MODELO.fit$param_summary
  
  PARAMETROS = PARAMETROS[-c(5:10), ]
  
  PAR = PARAMETROS
  
  PARAMETROS$Parametros = row.names(PARAMETROS)
  PARAMETROS = PARAMETROS[, c(6, 1:5)] 
  sapply(PARAMETROS, class)
  character_vars <- lapply(PARAMETROS, class) == "numeric"
  PARAMETROS[, character_vars] <-
    round(PARAMETROS[, character_vars], digits = 2)
  
  head(PARAMETROS)
  
  
  x=AFOROS2$W
  y=AFOROS2$Q
  
  caudales_eq_mean=round(PAR[1, 2] * ((x-PAR[3, 2])^PAR[2, 2]),3)
  
  rss <- sum((caudales_eq_mean - y) ^ 2)  ## residual sum of squares
  tss <- sum((y - mean(y)) ^ 2)  ## total sum of squares
  r2_mean <- 1 - (rss/tss)
  
  R2_mean=round(r2_mean,2)
  
  
  caudales_eq_min=round(PAR[1, 1] * ((x-PAR[3, 1])^PAR[2, 1]),3)
  
  rss <- sum((caudales_eq_min - y) ^ 2)  ## residual sum of squares
  tss <- sum((y - mean(y)) ^ 2)  ## total sum of squares
  r2_min <- 1 - (rss/tss)
  
  R2_min=round(r2_min,2)
  
  
  caudales_eq_max=round(PAR[1, 3] * ((x-PAR[3, 3])^PAR[2, 3]),3)
  
  rss <- sum((caudales_eq_max - y) ^ 2)  ## residual sum of squares
  tss <- sum((y - mean(y)) ^ 2)  ## total sum of squares
  r2_max <- 1 - (rss/tss)
  R2_max=round(r2_max,2)
  
  R2_ppal=max(c(R2_max,R2_mean,R2_min))
  
  if (R2_ppal==R2_max){
    y_curva=CAUDALES$upper
    eq=paste(
      "Q=",
      round(PAR[1, 3], 2),
      "(h -",
      round(PAR[3, 3], 2),
      ") ^",
      round(PAR[2, 3], 2),
      "   R2=",
      R2_ppal
    )
  }
  if (R2_ppal==R2_min){
    y_curva=CAUDALES$lower
    eq=paste(
      "Q=",
      round(PAR[1, 1], 2),
      "(h -",
      round(PAR[3, 1], 2),
      ") ^",
      round(PAR[2, 1], 2),
      "   R2=",
      R2_ppal
    )
  }
  if (R2_ppal==R2_mean){
    y_curva=CAUDALES$median
    eq=paste(
      "Q=",
      round(PAR[1, 2], 2),
      "(h -",
      round(PAR[3, 2], 2),
      ") ^",
      round(PAR[2, 2], 2),
      "   R2=",
      R2_ppal
    )
  }
  
  Curva_Gasto_2 = plot_instr(code = {
    par(new = FALSE, mar = c(5.5, 5, 5, 5))
    plot(
      CAUDALES$h,
      y_curva,
      "l",
      main = paste(
        "Curva de gasto",
        NOMBRE,
        "
    Método Bayesiano",
        "
    ",
        AFOROS$Fecha[nrow(AFOROS)-1]
      ),
      sub = eq,
      xlab = "Altura lámina de agua, h (m)",
      ylab = "Caudal (m^3/s)",
      ylim = c(0, max(y_curva)),
      xlim = c(0, max(CAUDALES$h))
    )
    grid(
      nx=NULL,
      ny=NULL,
      lty=2,
      col="gray",
      lwd=1
    )
    par(new = TRUE)
    plot(
      AFOROS_TABLA$W,
      AFOROS_TABLA$Q,
      xaxt = "n",
      yaxt = "n",
      xlab = "",
      ylab = "",
      col = 'blue',
      ylim = c(0, max(y_curva)),
      xlim = c(0, max(CAUDALES$h))
    )
    
  })
  
  set.seed(1)
  
  Tabla_Resumen = as.data.frame(summary(MODELO.fit))
  
  AFOROS <- AFOROS2
  
  names(AFOROS_TABLA) = c("Fecha", "TEMP MAPA", "TEMP TOTUI")
  
  
  Tabla_Aforos <- AFOROS_TABLA %>%
    regulartable(col_keys = names(AFOROS_TABLA),
                 cwidth = 0.2,
                 cheight = 0.1) %>% autofit()
  Tabla_Aforos = set_table_properties(Tabla_Aforos, width = 1, layout = "autofit")
  
  names(AFOROS_TABLA) = c("Fecha", "MAPA", "TOTUI")
  
  PARAMETROS <- PARAMETROS %>%
    regulartable(col_keys = names(PARAMETROS),
                 cwidth = 0.15,
                 cheight = 0.1) %>% autofit()
  PARAMETROS = set_table_properties(PARAMETROS, width = 0.8, layout = "autofit")
  
  x=AFOROS$MAPA
  y=AFOROS$TOTUI
  
  #Método lineal caudal-nivel
  linear=lm(y~x)
  linear$coefficients
  coef=linear$coefficients
  coef_lineal_1=coef[1]
  coef_lineal_2=coef[2]
  
  caudales_lineal= linear$coefficient[1]+linear$coefficient[2]*x
  
  #Cálculo del R2
  rss <- sum((caudales_lineal - y) ^ 2)  ## residual sum of squares
  tss <- sum((y - mean(y)) ^ 2)  ## total sum of squares
  r2lineal <- 1 - rss/tss
  R2_lineal=r2lineal
  
  #Modelo logaritmico
  logar=lm(y~log(x))
  logar$coefficients
  coef=logar$coefficients
  coef_log_1=coef[1]
  coef_log_2=coef[2]
  
  caudales_log= logar$coefficient[2]*log(x)+logar$coefficient[1]
  
  #Cálculo del R2
  rss <- sum((caudales_log - y) ^ 2)  ## residual sum of squares
  tss <- sum((y - mean(y)) ^ 2)  ## total sum of squares
  r2log <- 1 - rss/tss
  
  R2_log=r2log
  
  #Modelo polinomial
  Poly= lm(y~x + I(x^2))
  Poly$coefficients
  coef=Poly$coefficients
  coef_poli_1=coef[1]
  coef_poli_2=coef[2]
  coef_poli_3=coef[3]
  
  poli=Poly$coefficient[1]+Poly$coefficient[2]*x+Poly$coefficient[3]*x^2   
  
  caudales_poli=Poly$coefficient[1]+Poly$coefficient[2]*x+Poly$coefficient[3]*x^2
  
  
  #Cálculo del R2
  rss <- sum((caudales_poli - y) ^ 2)  ## residual sum of squares
  tss <- sum((y - mean(y)) ^ 2)  ## total sum of squares
  r2poli <- 1 - rss/tss
  
  R2_poli=r2poli
  
  
  #Se crean las funciones lineal, logarítmica y polinomial
  
  func_lineal=function(x) coef_lineal_1+coef_lineal_2*x
  func_log=function(x) coef_log_1+(coef_log_2*log(x))
  func_poli=function(x) coef_poli_1+coef_poli_2*x+coef_poli_3*x^2
  
  #GRAFICAR CURVA DE GASTO LINEAL
  minx=0
  maxx=h_desborde
  Serie=seq(minx, maxx, by=0.1)
  Datos_y_serie=round(func_lineal(Serie),2)
  calibracion=data.frame(Serie,Datos_y_serie)
  Tabla_lin<- data.frame(Serie,Datos_y_serie)
  names(Tabla_lin)= c("Altura lámina de agua (m)", "Caudal (m^3/s)" )
  
  Tabla_lin <- Tabla_lin %>%
    regulartable(
      col_keys = names(Tabla_lin),
      cwidth = 0.2,
      cheight = 0.1
    ) %>% autofit()
  Tabla_lin = set_table_properties(Tabla_lin, width = 1, layout = "autofit")
  
  R2_lin=round(R2_lineal,2)
  ecuacion_lin=paste("Q =(",
                     round(coef_lineal_1,3),
                     ") + (",
                     round(coef_lineal_2,3),") H",
                     "   R2=", R2_lin)
  
  
  Curva_Gasto_3 = plot_instr(code = {
    par(new = FALSE, mar = c(5.5, 5, 5, 5))
    plot(
      Serie,
      Datos_y_serie,
      col = 'black',
      'l',
      main = paste(
        "Curva de correlación",
        " datos Mapa - Totui",
        "
    método lineal",
        "
    ",
        AFOROS$Fecha[nrow(AFOROS)-1]
      ),
      sub = paste("",
                  ecuacion_lin),
      xlab = "Altura lámina de agua, h (m)",
      ylab = "Caudal (m^3/s)",
      ylim = c(min(Datos_y_serie), (max(Datos_y_serie)+max(Datos_y_serie)*0.3)),
      xlim = c(0, max(Serie))
      
    )
    grid(
      nx=NULL,
      ny=NULL,
      lty=2,
      col="gray",
      lwd=1
    )
    par(new = TRUE)
    plot(
      AFOROS_TABLA$MAPA,
      AFOROS_TABLA$TOTUI,
      xaxt = "n",
      yaxt = "n",
      xlab = "",
      ylab = "",
      col = 'blue',
      ylim = c(min(Datos_y_serie), (max(Datos_y_serie)+max(Datos_y_serie)*0.3)),
      xlim = c(0, max(Serie))
    )
  })
  
  
  Qm3s_log=round(func_log(Serie),2)
  if (is.infinite(Qm3s_log[1])){
    y_lim_log=Qm3s_log[2]
    Qm3s_log[1]=Qm3s_log[2]
  }
  
  calibracion=data.frame(Serie,Qm3s_log)
  Tabla_log=data.frame(Serie,Qm3s_log)
  names(Tabla_log)= c("Altura lámina de agua (m)", "Caudal (m^3/s)" )
  
  Tabla_log <- Tabla_log %>%
    regulartable(
      col_keys = names(Tabla_log),
      cwidth = 0.2,
      cheight = 0.1
    ) %>% autofit()
  Tabla_log = set_table_properties(Tabla_log, width = 1, layout = "autofit")
  
  
  R2_log=round(R2_log,2)
  ecuacion_log=paste("y =(",
                     round(coef_log_1,3),
                     ")+(", 
                     round(coef_log_2,3),
                     "log(x))", 
                     "   R2=", R2_log )
  
  Curva_Gasto_4 = plot_instr(code = {
    par(new = FALSE, mar = c(5.5, 5, 5, 5))
    plot(
      Serie,
      Qm3s_log,
      col = 'black',
      'l',
      main = paste(
        "Curva de gasto",
        NOMBRE,
        "
    método logarítmico",
        "
    ",
        AFOROS$Fecha[nrow(AFOROS)-1]
      ),
      sub = paste("",
                  ecuacion_log),
      xlab = "Altura lámina de agua, h (m)",
      ylab = "Caudal (m^3/s)",
      ylim = c(y_lim_log, (max(Qm3s_log)+max(Qm3s_log)*0.3)),
      xlim = c(0, max(Serie))
    )
    grid(
      nx=NULL,
      ny=NULL,
      lty=2,
      col="gray",
      lwd=1
    )
    par(new = TRUE)
    plot(
      AFOROS_TABLA$W,
      AFOROS_TABLA$Q,
      xaxt = "n",
      yaxt = "n",
      xlab = "",
      ylab = "",
      col = 'blue'
    )
    
  })
  
  Qm3s_poli=round(func_poli(Serie),2)
  calibracion=data.frame(Serie,Qm3s_poli)
  Tabla_poli=data.frame(Serie,Qm3s_poli)
  names(Tabla_poli)= c("Altura lámina de agua (m)", "Caudal (m^3/s)" )
  
  Tabla_poli <- Tabla_poli %>%
    regulartable(
      col_keys = names(Tabla_poli),
      cwidth = 0.2,
      cheight = 0.1
    ) %>% autofit()
  Tabla_poli = set_table_properties(Tabla_poli, width = 1, layout = "autofit")
  
  R2_poli=round(R2_poli,2)
  ecuacion_poli=paste("y=(",
                      round(coef_poli_1,3),
                      ")+(",round(coef_poli_2,3),
                      "x)+(", 
                      round(coef_poli_3,3),"x^2)",
                      "   R2=", R2_poli)
  
  Curva_Gasto_5 = plot_instr(code = {
    par(new = FALSE, mar = c(5.5, 5, 5, 5))
    plot(
      Serie,
      Qm3s_poli,
      col = 'black',
      'l',
      main = paste(
        "Curva de gasto",
        NOMBRE,
        "
    método polinomial",
        "
    ",
        AFOROS$Fecha[nrow(AFOROS)-1]
      ),
      sub = ecuacion_poli,
      xlab = "Altura lámina de agua, h (m)",
      ylab = "Caudal (m^3/s)",
      ylim = c(min(Qm3s_poli), (max(Qm3s_poli)+max(Qm3s_poli)*0.3)),
      xlim = c(0, max(Serie))
    )
    grid(
      nx=NULL,
      ny=NULL,
      lty=2,
      col="gray",
      lwd=1
    )
    par(new = TRUE)
    plot(
      AFOROS_TABLA$W,
      AFOROS_TABLA$Q,
      xaxt = "n",
      yaxt = "n",
      xlab = "",
      ylab = "",
      col = 'blue',
      ylim = c(min(Qm3s_poli), (max(Qm3s_poli)+max(Qm3s_poli)*0.3)),
      xlim = c(0, max(Serie))
    )
  })
  
  curvas=data.frame(Datos_y_serie,Qm3s_log, Qm3s_poli, round(y_curva,2))
  Rs=data.frame(R2_lin,R2_log,R2_poli,R2_ppal)
  
  
  for (k in 1:length(curvas)){
    curva=curvas[k]
    for (j in 2:length(curva)){
      if (curva[[j,1]]<= -0.5){
        Rs[k]=0
      }
    }
  }
  
  
  R2=max(Rs)
  
  HCM_tabla <- seq(minimo, maximo, (maximo-minimo)/10)
  
  if (R2==R2_lin){
    ganador="Método lineal"
    y_curva_fin=Datos_y_serie
    eq_fin=ecuacion_lin
    y_lim = c(min(Datos_y_serie), max(Datos_y_serie))
    x_lim = c(0, max(Serie))
    y_curva_tabla=round(func_lineal(HCM_tabla),2)
  }
  if (R2==R2_log){
    ganador="Método logarítmico"
    y_curva_fin=Qm3s_log
    eq_fin=ecuacion_log
    y_lim = c(y_lim_log, max(Qm3s_log))
    x_lim = c(0, max(Serie))
    y_curva_tabla=round(func_log(HCM_tabla),2)
  }
  if (R2==R2_poli){
    ganador="Método polinomial"
    y_curva_fin=Qm3s_poli
    eq_fin=ecuacion_poli
    y_lim = c(min(Qm3s_poli), max(Qm3s_poli))
    x_lim = c(0, max(Serie))
    y_curva_tabla=round(func_poli(HCM_tabla),2)
  }
  
  if (R2==R2_ppal){
    ganador="Método bayesiano"
    y_curva_fin=y_curva
    eq_fin=eq
    y_lim = c(0, max(y_curva))
    x_lim = c(0, max(CAUDALES$h))
    y_curva_tabla=round(CAUDALES_tabla$median,2)
    
  }
  
  
  # 
  # Curva_Gasto_fin = plot_instr(code = {
  #   par(new = FALSE, mar = c(5.5, 5, 5, 5))
  #   plot(
  #     Serie,
  #     y_curva_fin,
  #     "l",
  #     main = paste(
  #       "SATMA RISARALDA",
  #       NOMBRE,
  #       "
  #   ",
  #       ganador,
  #       "
  #   ",
  #       AFOROS$Fecha[nrow(AFOROS)-1]
  #     ),
  #     sub = eq_fin,
  #     xlab = "Altura lámina de agua, h (m)",
  #     ylab = "Caudal (m^3/s)",
  #   )
  #   grid(
  #     nx=NULL,
  #     ny=NULL,
  #     lty=2,
  #     col="gray",
  #     lwd=1
  #   )
  #   
  #   par(new = TRUE)
  #   plot(
  #     AFOROS_TABLA$W[1:18],
  #     AFOROS_TABLA$Q[1:18],
  #     xaxt = "n",
  #     yaxt = "n",
  #     xlab = "",
  #     ylab = "",
  #     col = 'blue',
  #     ylim = y_lim,
  #     xlim = x_lim
  #   )
  #   par(new = TRUE)
  #   plot(
  #     AFOROS_TABLA$W[19:length(AFOROS_TABLA$W)],
  #     AFOROS_TABLA$Q[19:length(AFOROS_TABLA$Q)],
  #     xaxt = "n",
  #     yaxt = "n",
  #     xlab = "",
  #     ylab = "",
  #     col = 'blue',
  #     ylim = y_lim,
  #     xlim = x_lim
  #   )
  #   
  # })
  
  
  
  
  df_principal <- data.frame(Serie = Serie, y_curva_fin = y_curva_fin)
  
  # Crear un data frame para los aforos
  df_aforos1 <- data.frame(W = AFOROS_TABLA$W[1:18], Q = AFOROS_TABLA$Q[1:18])
  df_aforos2 <- data.frame(W = AFOROS_TABLA$W[19:length(AFOROS_TABLA$W)], Q = AFOROS_TABLA$Q[19:length(AFOROS_TABLA$Q)])
  
  # Crear el gráfico con eje secundario para df_porc
  grafico_final <- ggplot() +
    # Línea principal (Hcm_grande vs y_curva_fin)
    geom_line(data = df_principal, aes(x = Serie, y = y_curva_fin), color = "black") +
    
    # Puntos de aforos
    geom_point(data = df_aforos1, aes(x = W, y = Q), color = "blue") +
    geom_point(data = df_aforos2, aes(x = W, y = Q), color = "blue") +
    
    
    # Etiquetas y título
    labs(
      title = paste("
       SATMA RISARALDA","
      ", NOMBRE,"
      ", ganador, AFOROS$Fecha[nrow(AFOROS)-1]),
      x = paste("Altura lámina de agua, h (m)","
        
      ",eq_fin),
      y = "Caudal (m^3/s)"
    ) +
    
    # Ajustar la posición de la etiqueta del subtítulo
    theme(
      plot.margin = margin(0.5, 0.5, 1, 1, "cm"),  # Añadir margen inferior para el subtítulo
      
    ) +
    
    # Añadir un grid
    theme(panel.background = element_rect(fill = "white", colour = "grey50"))+
    theme(plot.background = element_rect(fill = "white"))+
    theme(panel.grid.major = element_line(color = 'gray', linetype = "dashed"))
  
  
  
  
  # Mostrar el gráfico
  print(grafico_final)
  
  
  
  
  df <- data.frame(Altura= round(HCM_tabla,2), Caudal= round(y_curva_tabla,2))
  
  tabla <- tableGrob(df, rows = NULL)
  
  
  Curva_Gasto_fin = plot_instr(code = {
    grid.arrange(grafico_final, tabla, ncol = 2, widths = c(6, 2))
  })
  
  
  REPORTE = read_docx() #Creates a variable with the report information
  
  Reporte_Curva_de_Gasto <- REPORTE %>%
    
    #Main title of the document
    body_add(paste("SISTEMA DE ALERTAS TEMPRANAS Y MONITOREO AMBIENTAL DE RISARALDA - SATMA","
  REPORTE DE CURVA DE GASTO","
  Punto de medición: ",NOMBRE),
             style = "heading 1",
             pos = "after") %>%
    body_add(" ") %>%
    body_add_par(" ") %>%
    #Printing the data source of the rating curve
    body_add_par(
      "En la siguiente tabla se observan los datos usados para la construcción de la curva de gasto para el punto de estudio:",
      style = "Normal",
      pos = "after"
    ) %>%
    body_add_par(" ") %>%
    body_add_flextable(Tabla_Aforos, pos = "after") %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    body_add_par(
      "Dichos datos configuran la colección de puntos que se observa en la figura mostrada a continuación:",
      style = "Normal",
      pos = "after"
    ) %>%
    body_add(Datos_Curva_Gasto, width = 5, height = 4) %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    body_add_par(
      paste("Con base en la anterior colección de puntos se realizan 4 curvas de gasto, una con un modelo probabilístico bayesiano, y otras 3 con metodologías convencionales recomendadas por el IDEAM (lineal, polinómica y logarítmica). Una vez realizadas las curvas, estas son evaluadas para descartar aquellas con valores negativos o con pendientes negativas para alturas de lámina de agua entre 0 m y la altura de desborde, el R2 de las curvas restantes es comparado y y se establecen los umbrales según la curva con el mejor R2. "),
      style = "Normal",
      pos = "after")%>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    #Adding the tourment winner result plotting.
    body_add_par(
      paste("El modelo probabilístico Bayesiano se basa en el modelo de ley de potencias con distribución bayesiana, eligiendo el mejor modelo obtenido a partir de los métodos gplm, gplm0, plm y plm0, para este caso específico el método con mejores resultados fue el",modelo),
      style = "Normal",
      pos = "after")%>%
    
    body_add_par(" ") %>%
    body_add(Torneo, width = 5, height = 4) %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    #Prints the data summary of the rating curve
    body_add_par(
      " Siguiendo la distribución mostrada a continuación:",
      style = "Normal",
      pos = "after"
    ) %>%
    body_add_par(" ") %>%
    body_add_flextable(PARAMETROS, pos = "after") %>%
    
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    #Prints the distribution of the rating curve, and the logaritmic rating curve
    body_add_par(
      "El modelo presentado nos entrega una curva que correlaciona la altura de la lámina de agua y el caudal en ese punto, la media de esta curva se observa en el siguiente gráfico, las líneas punteadas representan los límites superiores e inferiores de la estimación, es decir, su incertidumbre, mientras que los puntos dispersos son los datos obtenidos en aforos realizados previamente.",
      style = "Normal",
      pos = "after"
    ) %>%
    body_add_par(" ") %>%
    body_add(Curva_Gasto_1, width = 5, height = 4) %>%
    body_add_par(" ") %>%
    body_add(Grafico, width = 5, height = 4) %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    #Printing the final discharge rating curve including the trheshold alert labels
    body_add_par(
      "La curva de gasto que se deriva del modelo mencionado se muestra a continuación. En este método los datos de nivel-caudal son correlacionados siguiendo una trayectoria de la forma Q= a*(H-c)^b.",
      style = "Normal",
      pos = "after"
    ) %>%
    body_add_par(" ") %>%
    body_add(Curva_Gasto_2, width = 6, height = 5) %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    body_add_par(
      "A continuación, se presentan también curvas de gasto obtenidas con base en los métodos tradicionales que utiliza el IDEAM en su metodología para la obtención de las curvas de gasto (IDEAM 2007)."
    ) %>%
    body_add_par(" ") %>%
    body_add_par("Método lineal: ") %>%
    body_add_par("En este método los datos de nivel-caudal son correlacionados siguiendo una trayectoria de la forma Q= a + b* H. Obteniendo la curva de gasto mostrada a continuación.") %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    body_add(Curva_Gasto_3, width = 6, height = 5) %>%
    #body_add_flextable(Tabla_lin)%>%
    
    body_add_par(" ") %>%
    body_add_par("Método logarítmico: ") %>%
    body_add_par("En este método los datos de nivel-caudal son correlacionados siguiendo una trayectoria de la forma Q= a + b* ln(H). Obteniendo la curva de gasto mostrada a continuación.") %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    body_add(Curva_Gasto_4, width = 6, height = 5) %>%
    #body_add_flextable(Tabla_log)%>%
    
    body_add_par(" ") %>%
    body_add_par("Método polinomial: ") %>%
    body_add_par("En este método los datos de nivel-caudal son correlacionados siguiendo una trayectoria de la forma Q= a + b*H  + c*H^2. Obteniendo la curva de gasto mostrada a continuación.") %>%
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    body_add(Curva_Gasto_5, width = 6, height = 5) %>%
    #body_add_flextable(Tabla_lin)
    body_add_par(" ") %>%
    body_add_par(" ") %>%
    #Printing the final discharge rating curve including the trheshold alert labels
    body_add_par("La curva con mejor R2 se muestra a continuación, en el eje x se observa la altura de la lámina de agua en metros, en el eje vertical izquierdo la cantidad de caudal que pasa por el punto en dicha altura.") %>%
    body_add_par(" ") %>%
    body_add(Curva_Gasto_fin, width = 6, height = 5) %>%
    
    
    print(Reporte_Curva_de_Gasto,
          target = paste(i,". ",NOMBRE, "_Reporte_Curva_de_Gasto.docx"))
}

