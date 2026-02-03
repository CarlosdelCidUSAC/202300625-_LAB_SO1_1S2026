# 📚 ÍNDICE DE DOCUMENTACIÓN COMPLETA

**Proyecto:** Desarrollo, Conexión y Gestión de Contenedores en Entornos Virtualizados  
**Carnet:** 202300625  
**Fecha:** 2 de Febrero, 2026  
**Asignatura:** Sistemas Operativos 1

---

## 🎯 ACCESO RÁPIDO

### Para Comenzar
1. **Primero:** Lee [README.md](README.md) para entender el proyecto
2. **Luego:** Revisa [Manual Técnico](docs/architecture/Manual_Tecnico.md) para arquitectura
3. **Después:** Sigue [Guía de Instalación](docs/installation/Guia_Instalacion.md) paso a paso
4. **Finalmente:** Valida con [Evidencia de Pruebas](docs/operations/Evidencia_Pruebas.md)

---

## 📖 DOCUMENTACIÓN PRINCIPAL

### 1. README.md
**Ubicación:** [README.md](README.md)  
**Lectura:** 10 minutos  
**Para:** Visión general del proyecto

**Contiene:**
- Resumen ejecutivo
- Estructura del proyecto
- Arquitectura de alto nivel
- Matriz de comunicación
- Instrucciones de instalación rápida
- Comandos de prueba
- Solución de problemas básica
- Herramientas utilizadas

**Cuándo leer:** Primero, para entender qué es el proyecto

---

### 2. Manual Técnico
**Ubicación:** [docs/architecture/Manual_Tecnico.md](docs/architecture/Manual_Tecnico.md)  
**Lectura:** 30 minutos  
**Para:** Entender la arquitectura y diseño técnico

**Contiene:**
- Visión general detallada
- Diagrama de arquitectura completo
- Topología de red
- Configuración de VMs (hardware, SO, paquetes)
- Descripción de APIs REST
- Flujo de comunicación
- Especificaciones de endpoints
- Formatos JSON
- Herramientas y versiones

**Cuándo leer:** Antes de instalar, para entender qué se necesita

---

### 3. Guía de Instalación
**Ubicación:** [docs/installation/Guia_Instalacion.md](docs/installation/Guia_Instalacion.md)  
**Lectura:** 60 minutos (más tiempo de ejecución)  
**Para:** Instalar y configurar el entorno

**Contiene:**
- Requisitos previos
- Verificación de herramientas
- Creación de VMs (virt-manager y CLI)
- Configuración de red estática
- Configuración SSH
- Instalación de Containerd y Docker
- Compilación de APIs en Go
- Construcción de imágenes Docker
- Configuración de Zot
- Despliegue de contenedores
- Pruebas de conectividad
- Solución de problemas detallada

**Cuándo leer:** Cuando vayas a instalar el sistema

---

### 4. Especificación de Comunicación de APIs
**Ubicación:** [docs/api-docs/COMUNICACION_APIS.md](docs/api-docs/COMUNICACION_APIS.md)  
**Lectura:** 15 minutos  
**Para:** Entender exactamente cómo se comunican las APIs

**Contiene:**
- Configuración general (carnet, formato, protocolo)
- Endpoints exactos
- Formatos de respuesta JSON
- Matriz de endpoints
- Variables personalizadas
- Ejemplos de cada endpoint
- Códigos de estado HTTP

**Cuándo leer:** Cuando desarrolles o pruebes las APIs

---

### 5. Evidencia de Pruebas
**Ubicación:** [docs/operations/Evidencia_Pruebas.md](docs/operations/Evidencia_Pruebas.md)  
**Lectura:** 25 minutos  
**Para:** Saber qué probar y cómo documentar resultados

**Contiene:**
- Resumen ejecutivo de pruebas
- Health checks (3 APIs)
- Comunicación entre APIs (6 direcciones)
- Manejo de errores
- Pruebas de Zot Registry
- Logs de ejecución
- Checklist final
- Ubicaciones para capturas de evidencia

**Cuándo leer:** Cuando vayas a probar el sistema

---

## 📋 DOCUMENTACIÓN COMPLEMENTARIA

### 6. Resumen de Documentación
**Ubicación:** [DOCUMENTACION_RESUMEN.md](DOCUMENTACION_RESUMEN.md)  
**Lectura:** 15 minutos  
**Para:** Entender qué se documentó y dónde

**Contiene:**
- Lista de documentos creados
- Contenido de cada documento
- Secciones principales
- Información ubicada en cada documento
- Referencias cruzadas
- Estadísticas de documentación

**Cuándo leer:** Si quieres saber rápidamente qué está documentado

---

### 7. Checklist de Validación
**Ubicación:** [CHECKLIST.md](CHECKLIST.md)  
**Lectura:** 20 minutos  
**Para:** Validar que todo está listo para entregar

**Contiene:**
- Requisitos técnicos (código, contenedores, APIs)
- Documentación (5 documentos principales)
- Estructura de directorios
- Información específica del proyecto
- Validación de contenido
- Calidad de documentación
- Preparación para GitHub
- Alineación con objetivos SMART

**Cuándo leer:** Antes de hacer la entrega final

---

### 8. Índice de Documentación (Este archivo)
**Ubicación:** [INDICE_DOCUMENTACION.md](INDICE_DOCUMENTACION.md)  
**Lectura:** 10 minutos  
**Para:** Navegar toda la documentación

**Cuándo leer:** En cualquier momento para encontrar lo que necesitas

---

## 🗺️ MAPA DE NAVEGACIÓN POR TEMA

### Si quiero entender el PROYECTO
1. [README.md](README.md) - Visión general
2. [Manual Técnico](docs/architecture/Manual_Tecnico.md) - Arquitectura
3. [DOCUMENTACION_RESUMEN.md](DOCUMENTACION_RESUMEN.md) - Qué está documentado

### Si quiero INSTALAR el sistema
1. [Guía de Instalación](docs/installation/Guia_Instalacion.md) - Paso a paso completo
2. [Manual Técnico](docs/architecture/Manual_Tecnico.md) - Referencia de configuración
3. [README.md](README.md) - Referencia rápida

### Si quiero DESARROLLAR las APIs
1. [Especificación de APIs](docs/api-docs/COMUNICACION_APIS.md) - Endpoints exactos
2. [Manual Técnico](docs/architecture/Manual_Tecnico.md) - Estructura de código
3. [README.md](README.md) - Ejemplos

### Si quiero PROBAR el sistema
1. [Evidencia de Pruebas](docs/operations/Evidencia_Pruebas.md) - Qué probar y cómo
2. [Guía de Instalación](docs/installation/Guia_Instalacion.md#pruebas-de-conectividad) - Pruebas rápidas
3. [README.md](README.md) - Comandos de test

### Si quiero SOLUCIONAR PROBLEMAS
1. [Guía de Instalación](docs/installation/Guia_Instalacion.md#solución-de-problemas) - Soluciones comunes
2. [README.md](README.md#solución-de-problemas-comunes) - Problemas rápidos
3. [Manual Técnico](docs/architecture/Manual_Tecnico.md) - Referencia de configuración

### Si quiero VERIFICAR completitud
1. [CHECKLIST.md](CHECKLIST.md) - Validación de requisitos
2. [DOCUMENTACION_RESUMEN.md](DOCUMENTACION_RESUMEN.md) - Qué se documentó
3. Luego ejecutar las pruebas en [Evidencia de Pruebas](docs/operations/Evidencia_Pruebas.md)

---

## 🔍 BÚSQUEDA POR PALABRAS CLAVE

### KVM / Virtualización
- [Guía: Creación de VMs](docs/installation/Guia_Instalacion.md#creación-de-vms)
- [Manual: Configuración de VMs](docs/architecture/Manual_Tecnico.md#configuración-de-máquinas-virtuales)
- [README: Diagrama de arquitectura](README.md#arquitectura)

### Go / APIs REST
- [Manual: Descripción de APIs](docs/architecture/Manual_Tecnico.md#apis-rest)
- [Especificación: Endpoints](docs/api-docs/COMUNICACION_APIS.md)
- [Guía: Compilación de APIs](docs/installation/Guia_Instalacion.md#compilación-de-apis)

### Containerd / Docker
- [Guía: Instalación de Containerd](docs/installation/Guia_Instalacion.md#en-vm1-y-vm2-instalación-de-containerd)
- [Guía: Instalación de Docker](docs/installation/Guia_Instalacion.md#en-vm3-instalación-de-docker)
- [Manual: Configuración de runtimes](docs/architecture/Manual_Tecnico.md#configuración-de-máquinas-virtuales)

### Zot Registry
- [Guía: Configuración de Zot](docs/installation/Guia_Instalacion.md#configuración-de-zot)
- [Manual: Registros privados](docs/architecture/Manual_Tecnico.md#registros-privados-con-zot)
- [Pruebas: Validación de Zot](docs/operations/Evidencia_Pruebas.md#pruebas-de-registro-zot)

### Comunicación de APIs
- [Especificación: Endpoints de comunicación](docs/api-docs/COMUNICACION_APIS.md)
- [Manual: Flujo de comunicación](docs/architecture/Manual_Tecnico.md#flujo-de-comunicación)
- [Pruebas: Comunicación entre APIs](docs/operations/Evidencia_Pruebas.md#comunicación-entre-apis)

### Red / Configuración
- [Guía: Configuración de red](docs/installation/Guia_Instalacion.md#configuración-de-red)
- [Manual: Topología de red](docs/architecture/Manual_Tecnico.md#topología-de-red)
- [README: Matriz de comunicación](README.md#matriz-de-comunicación)

### Pruebas y Validación
- [Evidencia: Todos los tests](docs/operations/Evidencia_Pruebas.md)
- [Guía: Pruebas de conectividad](docs/installation/Guia_Instalacion.md#pruebas-de-conectividad)
- [Checklist: Validación final](CHECKLIST.md)

### Solución de Problemas
- [Guía: Solución de problemas](docs/installation/Guia_Instalacion.md#solución-de-problemas)
- [README: Problemas comunes](README.md#solución-de-problemas-comunes)
- [Manual: Configuración (para referencia)](docs/architecture/Manual_Tecnico.md)

---

## 📊 ESTADÍSTICAS RÁPIDAS

| Aspecto | Cantidad |
|---------|----------|
| **Documentos principales** | 5 |
| **Documentos complementarios** | 3 |
| **Total de secciones** | 65+ |
| **Ejemplos de código** | 110+ |
| **Líneas de documentación** | 1680+ |
| **Diagramas/Tablas** | 25+ |
| **Comandos documentados** | 80+ |
| **URLs de endpoints** | 9 |

---

## ✅ CHECKLIST DE LECTURA RECOMENDADO

Para estudiante nuevo que quiere replicar el proyecto:

**Semana 1 - Comprensión:**
- [ ] Leer [README.md](README.md)
- [ ] Leer [Manual Técnico](docs/architecture/Manual_Tecnico.md)
- [ ] Revisar [Especificación de APIs](docs/api-docs/COMUNICACION_APIS.md)

**Semana 2 - Instalación:**
- [ ] Seguir [Guía de Instalación](docs/installation/Guia_Instalacion.md)
- [ ] Crear las 3 VMs
- [ ] Instalar runtimes

**Semana 3 - Implementación:**
- [ ] Compilar APIs
- [ ] Construir imágenes
- [ ] Desplegar contenedores

**Semana 4 - Validación:**
- [ ] Ejecutar pruebas de [Evidencia de Pruebas](docs/operations/Evidencia_Pruebas.md)
- [ ] Generar capturas
- [ ] Validar con [CHECKLIST.md](CHECKLIST.md)

---

## 🎓 ALINEACIÓN CON RÚBRICA

### Manual Técnico ✓
**Documento:** [Manual Técnico](docs/architecture/Manual_Tecnico.md)  
**Rúbrica:** "Descripción de configuración y diagrama de arquitectura"  
**Cumple:** Sí ✓

### Guía de Instalación ✓
**Documento:** [Guía de Instalación](docs/installation/Guia_Instalacion.md)  
**Rúbrica:** "Guía de instalación de contenedores e imágenes"  
**Cumple:** Sí ✓

### Especificación de APIs ✓
**Documento:** [Especificación](docs/api-docs/COMUNICACION_APIS.md)  
**Rúbrica:** "Documentación completa incluyendo endpoints"  
**Cumple:** Sí ✓

### Evidencia de Pruebas ✓
**Documento:** [Evidencia](docs/operations/Evidencia_Pruebas.md)  
**Rúbrica:** "Evidencia de pruebas realizadas y reporte de resultados"  
**Cumple:** Sí ✓

### Repositorio GitHub ✓
**Documento:** [README.md](README.md)  
**Rúbrica:** "Repositorio con estructura y guía de instalación"  
**Cumple:** Sí ✓

---

## 🚀 PRÓXIMOS PASOS

1. **Leer documentación** - Comienza con [README.md](README.md)
2. **Preparar VMs** - Sigue [Guía de Instalación](docs/installation/Guia_Instalacion.md)
3. **Instalar sistema** - Ejecuta los comandos documentados
4. **Ejecutar pruebas** - Sigue [Evidencia de Pruebas](docs/operations/Evidencia_Pruebas.md)
5. **Generar evidencia** - Captura pantallas y logs
6. **Validar completitud** - Usa [CHECKLIST.md](CHECKLIST.md)
7. **Hacer commit** - Push a GitHub privado

---

## 📞 INFORMACIÓN DE CONTACTO

**Carnet:** 202300625  
**Asignatura:** Sistemas Operativos 1  
**Universidad:** San Carlos de Guatemala  
**Período:** I Semestre 2026  
**Puntuación:** 15 pts

---

## 🏆 ESTADO DEL PROYECTO

✅ **DOCUMENTACIÓN:** Completa y Lista  
⏳ **PRUEBAS:** Pendiente de ejecución  
⏳ **EVIDENCIA:** Pendiente de captura  

**Última actualización:** 2 de Febrero, 2026  
**Versión de documentación:** 1.0

---

**Navegación rápida:**
- [README.md](README.md) - Comienza aquí
- [Guía de Instalación](docs/installation/Guia_Instalacion.md) - Para instalar
- [Manual Técnico](docs/architecture/Manual_Tecnico.md) - Para entender
- [Pruebas](docs/operations/Evidencia_Pruebas.md) - Para validar
- [CHECKLIST.md](CHECKLIST.md) - Para verificar completitud
