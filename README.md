
# 📡 Spectrum Visualizer

**Versión:** 1.0  
**Autores:** Andrés Felipe Franco Téllez – 20221978031  
Andrés Felipe Rincón Sánchez – 20221978013  
**Materia:** Gestión de Redes Telemáticas  
**Fecha:** Mayo 2025  

---

## 📘 Descripción

**Spectrum Visualizer** es una aplicación móvil interactiva desarrollada con Flutter que permite modelar, analizar y visualizar el comportamiento del espectro radioeléctrico. Los usuarios pueden configurar señales electromagnéticas, ajustar parámetros del sistema como temperatura y ancho de banda, y visualizar los resultados mediante una gráfica espectral dinámica que incluye indicadores como ruido térmico, relación señal/ruido (SNR) e interferencias entre señales.

---

## 🎯 Objetivos

- Diseñar una herramienta que facilite la comprensión del espectro radioeléctrico.
- Permitir la configuración de señales con atributos como frecuencia, potencia y ancho de banda.
- Implementar cálculos como el ruido térmico y la SNR con base en fundamentos teóricos.
- Visualizar los resultados mediante gráficas interactivas y paneles informativos.

---

## ⚙️ Requisitos del Sistema

### Para usuarios finales:
- Dispositivo Android con Android 8.0 o superior.
- Mínimo 2 GB de RAM.
- Resolución recomendada: 720x1280 px.
- Permisos de almacenamiento habilitados para exportar CSV.

### Para desarrolladores:
- Flutter SDK (v3.x o superior).
- Android Studio o Visual Studio Code con plugins de Flutter y Dart.
- Java JDK 11 o superior.
- Sistema operativo: Windows 10+, macOS 10.14+ o Linux.
- Emulador o dispositivo Android conectado por USB.

---

## 🚀 Instalación

### Desde código fuente:

```bash
git clone https://github.com/ItsFranco666/Spectrum_Visualizer.git
cd spectrum_visualizer
flutter pub get
flutter run
```

### Para generar APK:

```bash
flutter build apk --release
```

El APK se encuentra en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Para instalarlo, transfiere el archivo al teléfono y activa la opción de “Instalar apps de fuentes desconocidas”.

---

## 🧩 Arquitectura y Tecnologías Utilizadas

- **Flutter**: Framework principal multiplataforma.
- **Provider**: Gestión de estado reactiva.
- **fl_chart**: Visualización del espectro.
- **shared_preferences**: Persistencia local.
- **permission_handler**: Permisos en Android.
- **csv**, **path_provider**: Exportación de datos.
- Arquitectura en capas: Presentación (widgets), Lógica (provider), Modelos (`signal.dart`, `spectrum_data.dart`).

---

## 🧪 Estructura del Proyecto

- `main.dart`: Punto de entrada de la app.
- `HomeScreen`: Vista principal con navegación por pestañas.
- `SignalInputForm`: Formulario para ingresar señales.
- `SystemParametersForm`: Configuración de temperatura y ancho de banda.
- `SpectrumChart`: Genera y muestra la gráfica del espectro.
- `SpectrumProvider`: Lógica del sistema, cálculos y gestión de estado.
- Modelos:
  - `Signal`: Representa cada señal configurada.
  - `SpectrumData`: Almacena resultados de análisis espectral.

---

## 📊 Flujo de Trabajo

1. El usuario define cuántas señales desea ingresar (entre 3 y 10).
2. Configura cada señal con sus parámetros: potencia, ancho de banda y frecuencia central.
3. Define la temperatura y ancho de banda total del sistema.
4. Presiona el botón **Calcular**, que ejecuta los cálculos:
   - Ruido térmico: `N = 10 * log10(k * T * Bw * 10^6) + 30 [dBm]`
   - Cálculo de SNR y detección de interferencias.
5. Se muestra el resultado en una gráfica interactiva con zoom, tooltips y leyenda.

---

## 📎 Enlaces

- 📁 Repositorio: [https://github.com/ItsFranco666/Spectrum_Visualizer](https://github.com/ItsFranco666/Spectrum_Visualizer)
- 📄 Informe PDF: [Ver informe técnico](./Informe_de_aplicacion.pdf)
- 📘 Manual de Usuario: [Ver manual](./Manual_de_usuario_spectrum_visualizer.pdf)

---

> Proyecto desarrollado como parte del curso de **Redes Inalámbricas** - Universidad Distrital Francisco José de Caldas.
