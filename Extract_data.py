import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import statistics
from sqlalchemy import create_engine
import pymysql
from datetime import datetime, timedelta
from os import environ as env
import matplotlib.pyplot as plt


env['DB_USER']='intelneg'
env['DB_PASSWORD']='intelneg2022'
env['DB_HOST']='10.1.4.80'
env['DB_PORT']='3306'
env['DB_NAME']='albatros_db_v1_2_utp'

env['DB_USER_2']='usrConsulta'
env['DB_PASSWORD_2']='C0n5u1t4S4T2024'
env['DB_HOST_2']='10.1.4.51'
#env['DB_HOST_2']='201.131.90.70'
env['DB_PORT_2']='3306'
env['DB_NAME_SATMA']='albatros_sat_rda1_db'


env['DB_URL']="mysql+pymysql://{user}:{password}@{host}:{port}/{name}".format(
    user=env['DB_USER'],
    password=env['DB_PASSWORD'],
    host=env['DB_HOST'],
    port=env['DB_PORT'],
    name=env['DB_NAME']
    )


env['DB_URL_2']="mysql+pymysql://{user}:{password}@{host}:{port}/{name}".format(
    user=env['DB_USER_2'],
    password=env['DB_PASSWORD_2'],
    host=env['DB_HOST_2'],
    port=env['DB_PORT_2'],
    name=env['DB_NAME_SATMA']
    )

def filtrar_temperaturas(df):
    return df[(df['Temperatura'] > 0) & (df['Temperatura'] <= 50)]


def redondear_horas(df):
    df['stationTime'] = pd.to_datetime(df['stationTime'])
    df['stationTime'] = df['stationTime'].dt.floor('5T')
    return df

fecha_inicio= datetime.strptime('2023-06-01 00:00:00', '%Y-%m-%d %H:%M:%S')
fecha_actual = datetime.strptime('2023-10-01 00:00:00', '%Y-%m-%d %H:%M:%S')
hora_actual_str = fecha_actual.strftime('%Y-%m-%d %H:%M:%S')
hora_inicio_str = fecha_inicio.strftime('%Y-%m-%d %H:%M:%S')
engine = create_engine(env.get('DB_URL'), echo=True)
engine2 = create_engine(env.get('DB_URL_2'), echo=True)

query1= " SELECT stationTime, round(temperature, 2) as Temperatura, round(realPrecipitation, 2) AS Lluvia FROM tst_totui WHERE stationTime BETWEEN %s AND %s and temperature is not null and realPrecipitation is not null order by stationTime asc;"
datos_totui= pd.read_sql(query1, engine,  params=(hora_inicio_str, hora_actual_str))

#plt.plot(datos_totui['stationTime'], datos_totui['Temperatura'], label='Temperatura')


query2= " SELECT stationTime, round(temperature, 2) as Temperatura, round(realPrecipitation, 2) AS Lluvia FROM tst_est_r_mapa WHERE stationTime BETWEEN %s AND %s and temperature is not null and realPrecipitation is not null order by stationTime asc;"
datos_rio_mapa= pd.read_sql(query2, engine2,  params=(hora_inicio_str, hora_actual_str))


query3= " SELECT stationTime, round(temperature, 2) as Temperatura, round(realPrecipitation, 2) AS Lluvia FROM tst_eht_rio_monos_la_celia WHERE stationTime BETWEEN %s AND %s and temperature is not null and realPrecipitation is not null order by stationTime asc;"
datos_rio_monos= pd.read_sql(query3, engine2,  params=(hora_inicio_str, hora_actual_str))


query4= " SELECT stationTime, round(temperature, 2) as Temperatura, round(realPrecipitation, 2) AS Lluvia FROM tst_eht_q_la_liborina_la_celia WHERE stationTime BETWEEN %s AND %s and temperature is not null and realPrecipitation is not null order by stationTime asc;"
datos_q_liboriana= pd.read_sql(query4, engine2,  params=(hora_inicio_str, hora_actual_str))

#filtrar los datos para eliminar valores con temperatura <= 0 o > 50
datos_totui = filtrar_temperaturas(datos_totui)
datos_rio_mapa = filtrar_temperaturas(datos_rio_mapa)
datos_rio_monos = filtrar_temperaturas(datos_rio_monos)
datos_q_liboriana = filtrar_temperaturas(datos_q_liboriana)


# Aplicar la función a cada DataFrame
datos_totui = redondear_horas(datos_totui)
datos_rio_mapa = redondear_horas(datos_rio_mapa)
datos_rio_monos = redondear_horas(datos_rio_monos)
datos_q_liboriana = redondear_horas(datos_q_liboriana)

# Agrupar por la hora redondeada y calcular el promedio
datos_totui = datos_totui.groupby('stationTime').mean().reset_index()
datos_rio_mapa = datos_rio_mapa.groupby('stationTime').mean().reset_index()
datos_rio_monos = datos_rio_monos.groupby('stationTime').mean().reset_index()
datos_q_liboriana = datos_q_liboriana.groupby('stationTime').mean().reset_index()

df_merged_mapa= datos_totui.merge(datos_rio_mapa, on='stationTime', suffixes=('_totui', '_rio_mapa'))
df_merged_monos= datos_totui.merge(datos_rio_monos, on='stationTime', suffixes=('_totui', '_rio_monos'))
df_merged_liboriana= datos_totui.merge(datos_q_liboriana, on='stationTime', suffixes=('_totui', '_q_liboriana'))

df_merged_completos = datos_totui.merge(datos_rio_mapa, on='stationTime', suffixes=('_totui', '_rio_mapa'))
df_merged_completos = df_merged_completos.merge(datos_rio_monos, on='stationTime', suffixes=('', '_rio_monos'))
df_merged_completos = df_merged_completos.merge(datos_q_liboriana, on='stationTime', suffixes=('', '_q_liboriana'))
df_merged_completos.rename(columns={'Temperatura': 'Temperatura_rio_monos', 'Lluvia': 'Lluvia_rio_monos'}, inplace=True)

df_merged_mapa.to_csv('df_merged_mapa.csv', index=False)
df_merged_monos.to_csv('df_merged_monos.csv', index=False) 
df_merged_liboriana.to_csv('df_merged_liboriana.csv', index=False)
df_merged_completos.to_csv('df_merged_completos.csv', index=False)

datos_rio_mapa.to_csv('datos_rio_mapa.csv', index=False)


df= pd.DataFrame(columns=['Temperatura_rio_mapa','Temperatura_rio_monos', 'Temperatura_q_liboriana'])
df['Temperatura_rio_mapa'] = df_merged_completos['Temperatura_rio_mapa']
df['Temperatura_rio_monos'] = df_merged_completos['Temperatura_rio_monos']
df['Temperatura_q_liboriana'] = df_merged_completos['Temperatura_q_liboriana']

#DATOS OBTENIDOS DE LA REGRESIÓN IA TEMPERATURA:

"""
    Merged mapa: loss: 0.0642131388316903    R2: 0.9357868611683097
    Merged monos: loss: 0.19
    Merged liboriana: loss: 0.204
    Merged completos: loss: 1.17 en temperatura
"""


datos_nuevos_Totui= pd.read_csv('predicted_temperatures.csv')
datos_nuevos_Totui["Predicted_Temperature"] = datos_nuevos_Totui["Predicted_Temperature"].round(2)

datos_nuevos_Totui['stationTime'] = pd.to_datetime(datos_nuevos_Totui['stationTime'])
datos_nuevos_Totui['date'] = datos_nuevos_Totui['stationTime'].dt.date

max_min_temperatures = datos_nuevos_Totui.groupby('date')['Predicted_Temperature'].agg(['max', 'min']).reset_index()

max_min_temperatures.rename(columns={'max': 'Max_Temperature', 'min': 'Min_Temperature'}, inplace=True)

max_min_temperatures["GDD"]= (((max_min_temperatures["Max_Temperature"] + max_min_temperatures["Min_Temperature"])/2)-10).round(2)

max_min_temperatures.to_csv('max_min_temperatures_Balboa.csv', index=False)



# Objetivos: GDD, CORRELACION GDD/PESO, CORRELACION DIAS/PESO, NORMALIZACION DATOS CUAJADOS, CUAJADO/PESO, CUJADO/DIAS

# PORCENTAJE DE SIGATOKA, CANTIDAD HOJAS/PESO, SIGATOKA/PESO

# GRAFICAS DE DISTRIBUCIÓN NORMAL PARA TEMPERATURA Y GDD

# CURVA DE CORRELACIÓN GDD/PESO ENTRE LOS PUNTOS DE MEDICIÓN 