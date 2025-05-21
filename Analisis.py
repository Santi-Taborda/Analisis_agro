# Objetivos: GDD, NORMALIZACION DATOS CUAJADOS, CUAJADO/PESO, CUJADO/DIAS

# PORCENTAJE DE SIGATOKA, CANTIDAD HOJAS/PESO, SIGATOKA/PESO

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

tabla_platano= pd.read_excel("C:/Users/Santi/Documents/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Plátano")
tabla_aguacate= pd.read_excel("C:/Users/Santi/Documents/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Aguacate")

tabla_platano_completa= pd.read_excel("C:/Users/Santi/Documents/Python/Analisis_agro/Consolidado datos proyecto de grado (sin fotos).xlsx", sheet_name="Plátano Belén de Umbría.")


Generar_gráfico_de_dispersión(tabla_platano, 'GDD Plátano', 'Peso promedio (kg)', 'GDD plátano vs Peso promedio por municipio', 'GDD', 'Peso promedio (kg)')
Generar_gráfico_de_dispersión(tabla_aguacate, 'GDD Aguacate', 'Peso promedio (kg)', 'GDD aguacate vs Peso promedio por municipio', 'GDD', 'Peso promedio (kg)')
Generar_gráfico_de_dispersión(tabla_platano, 'Días calendario plátano', 'Peso promedio (kg)', 'Días calendario plátano vs Peso promedio por municipio', 'Días calendario', 'Peso promedio (kg)')
Generar_gráfico_de_dispersión(tabla_aguacate, 'Días calendario aguacate', 'Peso promedio (kg)', 'Días calendario aguacate vs Peso promedio por municipio', 'Días calendario', 'Peso promedio (kg)')

