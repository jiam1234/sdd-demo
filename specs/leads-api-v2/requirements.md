# Leads API v2 — requisitos funcionales

## Objetivo

Formalizar el contrato funcional de Leads API v2 antes de modificar su implementación. Este documento, `business-rules.md`, `acceptance-tests.feature` y `openapi.yaml` forman una especificación versionable y trazable.

## Alcance

La API permite crear leads y asignarles un score mediante los endpoints existentes. Los datos se mantienen en memoria durante la ejecución del proceso.

## Requisitos funcionales

### FR-01 — Crear un lead

`POST /leads` acepta `name` y `source`. Ambos son cadenas. El servidor aplica `trim` antes de validar; cuenta puntos de código Unicode en los valores normalizados y exige entre 1 y 100 para `name` y entre 1 y 50 para `source`. Almacena y devuelve esos valores normalizados. El servidor genera el `id` y establece `status` en `new` y `score` en `0`. La respuesta exitosa es `201 Created` con el recurso creado.

### FR-02 — Asignar score y clasificar un lead

`POST /leads/{id}/score` acepta el score requerido como entero entre 0 y 100 inclusive. El servidor actualiza el score y recalcula el estado en cada asignación: 0–70 `new`, 71–89 `qualified`, 90–100 `vip`. La respuesta exitosa es `200 OK` con el recurso actualizado. Un lead cuyo estado era `vip` puede pasar a `new` al recibir un score de 70 o menor.

### FR-03 — Validar solicitudes y rechazar campos no admitidos

La API rechaza solicitudes inválidas con `400 Bad Request`. Para crear un lead, el cliente no puede enviar `id`, `status` ni `score`; tampoco puede enviar otras propiedades no documentadas. El cuerpo de asignación de score tampoco admite propiedades no documentadas. Los cuerpos de solicitud se envían como JSON.

### FR-04 — Informar errores de forma uniforme

Las respuestas de error usan el esquema `{ "code": "ERROR_CODE", "message": "Descripción del error" }`. La validación produce `400 Bad Request`, un ID de lead inexistente produce `404 Not Found`, un tipo de contenido no admitido produce `415 Unsupported Media Type` y un fallo inesperado produce `500 Internal Server Error`.

### FR-05 — Verificar errores inesperados en pruebas controladas

El mapeo de errores inesperados se verifica mediante una prueba de integración con una dependencia de almacenamiento sustituida por un doble de prueba que lanza una excepción durante una operación normal. La solicitud se realiza por HTTP al endpoint existente y debe producir `500` con el esquema común. La inyección existe solo en el test harness; no se añade un endpoint de fallo ni otra ruta de producción.

## Requisitos no funcionales aplicables

### NFR-01 — Contrato documentado

Los dos endpoints y sus solicitudes, respuestas y errores se describen en OpenAPI 3.0. El contrato debe conservar los límites, campos requeridos, estados permitidos y respuestas definidos en FR-01 a FR-05 y BR-01 a BR-07.

## Restricciones y exclusiones

- **BR-07:** los datos permanecen en memoria; no se garantiza su conservación tras reiniciar el proceso.
- No se incorpora autenticación, persistencia, idempotencia ni detección de duplicados.
- La fuente (`source`) es texto libre; no hay una enumeración de fuentes.
- Esta iteración define especificaciones; no cambia la implementación.
- No se añaden otros endpoints ni reglas de negocio.

## Criterios de aceptación

1. **CA-01 / FR-01 / BR-01, BR-02:** un lead válido se crea con `201`, ID generado, `name` y `source` devueltos ya normalizados, estado `new` y score `0`.
2. **CA-02 / FR-01, FR-03 / BR-01, BR-02:** se rechazan con `400` nombre o fuente ausentes, no textuales, vacíos tras `trim`, o que excedan sus límites de puntos de código Unicode después de `trim`.
3. **CA-03 / FR-02 / BR-03, BR-04, BR-05:** asignar 0, 70, 71, 89, 90 o 100 devuelve `200`, guarda el score y calcula respectivamente los estados `new`, `new`, `qualified`, `qualified`, `vip` y `vip`.
4. **CA-04 / FR-02, FR-03 / BR-03:** se rechazan con `400` scores negativos, mayores que 100, ausentes, decimales o de tipo no entero.
5. **CA-05 / FR-02 / BR-05, BR-06:** asignar score a un ID inexistente devuelve `404` con el formato uniforme de error.
6. **CA-06 / FR-02 / BR-04, BR-05:** después de asignar 95 a un lead y clasificarlo `vip`, asignar 70 lo cambia a `new`.
7. **CA-07 / FR-03 / BR-02:** las propiedades adicionales en cualquier solicitud y los campos controlados por el servidor en una creación se rechazan con `400`.
8. **CA-08 / FR-03, FR-04 / BR-06:** tipo de contenido no admitido devuelve `415`; todas las respuestas de error cumplen el esquema común.
9. **CA-09 / FR-04, FR-05 / BR-06:** un fallo forzado por el doble de almacenamiento de la prueba produce `500`, `code: INTERNAL_ERROR` y un `message` no vacío al llamar un endpoint existente; no se expone un endpoint artificial.
