# OXIBARA
OXIBARA es una aplicación móvil para visualizar los niveles de saturación de oxígeno en tiempo real mediante comunicación BlueTooth. La medición se realizó con un sensor MAX30102 y la comunicación se logró mediante un módulo HC-05.

La aplicación recibe valores de Spo2 en tiempo real y actualiza automáticamente la interfaz gráfica.Además, se diseñó con un enfoque amigable al utilziar indicadores visuales dinámicos y capibaras que representaran el estado de oxigenación del usuario.

Variables recibidas:
-Saturación de oxígeno (SpO2)
-Frecuencia cardíaca (Heart Rate) (opcional para futuras implementaciones)

Hardware utilizado:
-MAX30102: Sensor biomédico que permite obtener la oxigenación en sangre y frecuencia cardiaca
-HC-05: Módulo utilizado para la comunicación BT
-ESP-32: Microprocesador que procesa y envías los datos vía BT

Estados de Spo2:
| Rango      | Estado     |
| ---------- | ---------- |
| 95% - 100% | Óptimo     |
| 91% - 94%  | Vigilancia |
| 86% - 90%  | Alerta     |
|   < 86%    | Crítico    |


Link del video DEMO:
https://drive.google.com/file/d/1JoPOsWsl6Cuxxcg49uOqU-TfG1j2Oi-R/view?usp=drivesdk
