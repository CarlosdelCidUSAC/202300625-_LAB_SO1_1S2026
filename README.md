# 202300625-_LAB_SO1_1S2026

Proyecto de virtualización con 3 VMs, APIs REST en Go y registro privado ZOT. El objetivo es desplegar servicios contenerizados en Containerd y Docker, con comunicación cruzada entre APIs y registro de imágenes en un entorno aislado.

---

## Índice de documentación

- Manual Técnico: [docs/architecture/Manual_Tecnico.md](docs/architecture/Manual_Tecnico.md)
- Guía de Instalación: [docs/installation/Guia_Instalacion.md](docs/installation/Guia_Instalacion.md)
- Evidencia de Pruebas: [docs/operations/Evidencia_Pruebas.md](docs/operations/Evidencia_Pruebas.md)
- Comunicación entre APIs: [docs/api-docs/COMUNICACION_APIS.md](docs/api-docs/COMUNICACION_APIS.md)
- Estructura del repositorio: [STRUCTURE.md](STRUCTURE.md)

---

## Estructura rápida

- APIs (Go): [api-services/](api-services/)
- Dockerfiles: [api-services/dockerfiles](api-services/dockerfiles)
- Registro ZOT: [container-registry/](container-registry/)
- Scripts de despliegue: [scripts/](scripts/)
- Configuración de VMs: [vm-config/](vm-config/)

---

## Notas de evaluación

- La documentación se encuentra organizada en la carpeta [docs/](docs/).
- La evidencia de pruebas debe incluir JSON con `connection: true` y manejo de errores con `connection: false`.
- El historial de commits debe reflejar trabajo progresivo.
