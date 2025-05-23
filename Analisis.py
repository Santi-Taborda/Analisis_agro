# Objetivos:  CUAJADO/PESO

# GRAFICAS DE DISTRIBUCIÓN NORMAL PARA TEMPERATURA Y GDD

# CURVA DE CORRELACIÓN GDD/PESO ENTRE LOS PUNTOS DE MEDICIÓN

# CURVA DE CORRELACIÓN DIAS/PESO ENTRE LOS PUNTOS DE MEDICIÓN

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import statistics
import matplotlib.pyplot as plt
import openpyxl


def Generar_gráfico_de_dispersión (tabla, xlabel, ylabel, title, param_x, param_y):
    for municipio, color in zip(tabla['Municipio'].unique(), ['blue', 'green', 'orange']):
        datos = tabla[tabla['Municipio'] == municipio]
        x = datos[param_x]
        y = datos[param_y]
        plt.scatter(
            x,
            y,
            label=municipio,
            color=color,
            s=80
    )
    x= tabla[param_x]
    y= tabla[param_y]

    # Ajuste polinómico de segundo grado
    if len(x) > 2:
        coef = np.polyfit(x, y, 2)
        poly2d_fn = np.poly1d(coef)
        x_suave = np.linspace(x.min(), x.max(), 100)
        plt.plot(x_suave, poly2d_fn(x_suave), color="black", linestyle='--')
        
        # R2 para ajuste cuadrático
        y_pred = poly2d_fn(x)
        ss_res = np.sum((y - y_pred) ** 2)
        ss_tot = np.sum((y - np.mean(y)) ** 2)
        r2 = 1 - (ss_res / ss_tot)
        
        # Ecuación en el gráfico
        ax = plt.gca()
        xlim = ax.get_xlim()
        ylim = ax.get_ylim()
        x_text = xlim[1] - 0.05 * (xlim[1] - xlim[0])
        y_text = ylim[0] + 0.05 * (ylim[1] - ylim[0])
        plt.text(
            x_text, y_text,
            f'y={coef[0]:.2e}x²+{coef[1]:.2f}x+{coef[2]:.2f}\n$R^2$={r2:.2f}',
            color="black", fontsize=10,
            ha='right', va='bottom'
        )

    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.title(title)
    plt.legend()
    plt.show()

def Generar_gráfico_de_dispersión_log (tabla, xlabel, ylabel, title, param_x, param_y):
    for municipio, color in zip(tabla['Municipio'].unique(), ['blue', 'green', 'orange']):
        datos = tabla[tabla['Municipio'] == municipio]
        x = datos[param_x]
        y = datos[param_y]
        plt.scatter(
            x,
            y,
            label=municipio,
            color=color,
            s=80
        )
    x = tabla[param_x]
    y = tabla[param_y]

    # Ajuste logarítmico: y = a*log(x) + b
    mask = x > 0  # Evita log(0) o negativos
    x_log = np.log(x[mask])
    y_log = y[mask]
    if len(x_log) > 1:
        coef = np.polyfit(x_log, y_log, 1)
        # Crear 100 puntos igualmente espaciados para suavizar la curva
        x_sorted = np.sort(x[x > 0])
        x_suave = np.linspace(x_sorted.min(), x_sorted.max(), 100)
        y_pred_suave = coef[0] * np.log(x_suave) + coef[1]
        plt.plot(x_suave, y_pred_suave, color="black", linestyle='--', label='Ajuste logarítmico')
        # R2 para ajuste logarítmico
        ss_res = np.sum((y[mask] - (coef[0]*x_log + coef[1])) ** 2)
        ss_tot = np.sum((y[mask] - np.mean(y[mask])) ** 2)
        r2 = 1 - (ss_res / ss_tot)
        # Ecuación en el gráfico
        ax = plt.gca()
        xlim = ax.get_xlim()
        ylim = ax.get_ylim()
        x_text = xlim[1] - 0.05 * (xlim[1] - xlim[0])
        y_text = ylim[0] + 0.05 * (ylim[1] - ylim[0])
        plt.text(
            x_text, y_text,
            f'y={coef[0]:.2f}·ln(x)+{coef[1]:.2f}\n$R^2$={r2:.2f}',
            color="black", fontsize=10,
            ha='right', va='bottom'
        )

    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.title(title)
    plt.legend()
    plt.show()

def Generar_gráfico_temporal(tabla, xlabel, ylabel, title, param_x, param_y, fecha_corte=None):
    datos = tabla.groupby(param_x)[param_y].mean().reset_index()
    x = datos[param_x]
    y = datos[param_y]

    if fecha_corte is not None:
        fecha_corte = pd.to_datetime(fecha_corte)
        mask = x < fecha_corte
        # Antes de la fecha_corte
        plt.plot(x[mask], y[mask], marker='o', linestyle='-', color='b', label=f'{ylabel} con flores')
        # Después (o igual) a la fecha_corte
        plt.plot(x[~mask], y[~mask], marker='o', linestyle='-', color='r', label=f'{ylabel} sin flores')
    else:
        plt.plot(x, y, marker='o', linestyle='-', color='b', label=ylabel)

    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.title(title)
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.legend()
    plt.show()

def Histograma_porcentaje_cuajado(tabla, titulo):
    # Histograma del porcentaje de cuajados en Belén de Umbría
    datos = tabla.groupby("Fecha")['Porcentaje cuajado'].mean().reset_index()
    plt.figure(figsize=(8,5))
    plt.hist(datos['Porcentaje cuajado'].dropna(), bins=20, color='skyblue', edgecolor='black')
    plt.xlabel('Porcentaje cuajado')
    plt.ylabel('Frecuencia')
    plt.title(titulo)
    plt.tight_layout()
    plt.show()


tabla_platano= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Plátano")
tabla_aguacate= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Aguacate")

tabla_platano_Belen= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Plátano Belén de Umbría.")
tabla_platano_Balboa= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Plátano Balboa")
tabla_platano_Pereira= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Plátano Pereira")

tabla_aguacate_Belen= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Aguacate Belén de Umbría")
tabla_aguacate_Balboa= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Aguacate Balboa")
tabla_aguacate_Pereira= pd.read_excel("C:/Users/giral/OneDrive/Documentos/EIS/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Aguacate Pereira")


Generar_gráfico_de_dispersión(tabla_platano, 'GDD Plátano', 'Peso promedio (kg)', 'GDD plátano vs Peso promedio por municipio', 'GDD', 'Peso promedio (kg)')
Generar_gráfico_de_dispersión(tabla_aguacate, 'GDD Aguacate', 'Peso promedio (kg)', 'GDD aguacate vs Peso promedio por municipio', 'GDD', 'Peso promedio (kg)')
Generar_gráfico_de_dispersión(tabla_platano, 'Días calendario plátano', 'Peso promedio (kg)', 'Días calendario plátano vs Peso promedio por municipio', 'Días calendario', 'Peso promedio (kg)')
Generar_gráfico_de_dispersión(tabla_aguacate, 'Días calendario aguacate', 'Peso promedio (kg)', 'Días calendario aguacate vs Peso promedio por municipio', 'Días calendario', 'Peso promedio (kg)')

Generar_gráfico_de_dispersión(tabla_platano, 'Peso promedio (kg)', 'GDD Plátano', 'Peso promedio vs GDD en plátano', 'Peso promedio (kg)', 'GDD')
Generar_gráfico_de_dispersión(tabla_platano, 'Peso promedio (kg)', 'Días calendario', 'Peso promedio vs Días calendario en plátano', 'Peso promedio (kg)', 'Días calendario')

Generar_gráfico_de_dispersión(tabla_aguacate, 'Peso promedio (kg)', 'GDD Aguacate', 'Peso promedio vs GDD en aguacate', 'Peso promedio (kg)', 'GDD')
Generar_gráfico_de_dispersión(tabla_aguacate, 'Peso promedio (kg)', 'Días calendario', 'Peso promedio vs Días calendario en aguacate', 'Peso promedio (kg)', 'Días calendario')


Generar_gráfico_temporal(tabla_platano_Belen, 'Fecha', 'Porcentaje sigatoka (%)', 'Tiempo vs Porcentaje de sigatoka en Belén de Umbría', 'Fecha', 'Porcentaje sigatoka')
Generar_gráfico_temporal(tabla_platano_Balboa, 'Fecha', 'Porcentaje sigatoka (%)', 'Tiempo vs Porcentaje de sigatoka en Balboa', 'Fecha', 'Porcentaje sigatoka')
Generar_gráfico_temporal(tabla_platano_Pereira, 'Fecha', 'Porcentaje sigatoka (%)', 'Tiempo vs Porcentaje de sigatoka en Pereira', 'Fecha', 'Porcentaje sigatoka')

Generar_gráfico_temporal(tabla_aguacate_Belen, 'Fecha', 'Porcentaje cuajado (%)', 'Tiempo vs Porcentaje de cuajado en Belén de Umbría', 'Fecha', 'Porcentaje cuajado', '2023-03-22')
Generar_gráfico_temporal(tabla_aguacate_Balboa, 'Fecha', 'Porcentaje cuajado (%)', 'Tiempo vs Porcentaje de cuajado en Balboa', 'Fecha', 'Porcentaje cuajado', '2023-02-15') 
Generar_gráfico_temporal(tabla_aguacate_Pereira, 'Fecha', 'Porcentaje cuajado (%)', 'Tiempo vs Porcentaje de cuajado en Pereira', 'Fecha', 'Porcentaje cuajado', '2023-03-06')

Histograma_porcentaje_cuajado(tabla_aguacate_Belen, 'Histograma del porcentaje de cuajados en Belén de Umbría')
Histograma_porcentaje_cuajado(tabla_aguacate_Balboa, 'Histograma del porcentaje de cuajados en Balboa')
Histograma_porcentaje_cuajado(tabla_aguacate_Pereira,'Histograma del porcentaje de cuajados en Pereira')

