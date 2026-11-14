# Leads API v2 — reglas de negocio

## Reglas

### BR-01 — Normalización y validación de nombre y fuente

`name` y `source` son obligatorios y deben ser cadenas. El servidor aplica `trim` antes de validar. Cuenta puntos de código Unicode del valor normalizado: `name` debe medir entre 1 y 100 inclusive y `source` entre 1 y 50 inclusive. Almacena y devuelve los valores normalizados. No se define una lista cerrada de fuentes.

### BR-02 — Identidad y campos gestionados por el servidor

El servidor genera el `id`. En la creación, el cliente no puede enviar `id`, `status`, `score` ni propiedades no documentadas. El estado y score iniciales son `new` y `0`. En la asignación de score tampoco se aceptan propiedades no documentadas.

### BR-03 — Dominio de score

El score es obligatorio, debe ser un entero y pertenece al intervalo inclusivo de 0 a 100.

### BR-04 — Umbrales de clasificación

| Score | Estado |
|---:|---|
| 0–70 | `new` |
| 71–89 | `qualified` |
| 90–100 | `vip` |

Los únicos estados definidos son `new`, `qualified` y `vip`.

### BR-05 — Recalcular estado en cada asignación

Cada asignación válida actualiza el score y recalcula el estado usando BR-04, sin depender del estado anterior. El estado puede subir o bajar; por ejemplo, `vip` pasa a `new` con score 70.

### BR-06 — Respuestas de error

Todos los errores usan el objeto `{ "code": "ERROR_CODE", "message": "Descripción del error" }`.

| Condición | HTTP | Código de error |
|---|---:|---|
| JSON mal formado, campos requeridos ausentes, tipos o valores inválidos, propiedades adicionales | 400 | `VALIDATION_ERROR` |
| ID de lead inexistente al asignar score | 404 | `LEAD_NOT_FOUND` |
| Tipo de contenido no admitido | 415 | `UNSUPPORTED_MEDIA_TYPE` |
| Fallo inesperado | 500 | `INTERNAL_ERROR` |

El texto de `message` describe el error sin sustituir el código estable.

La verificación de `500 INTERNAL_ERROR` se hace en una prueba de integración controlada: el test harness inyecta un doble de la dependencia de almacenamiento que lanza una excepción durante una solicitud a un endpoint existente. La prueba comprueba el estado HTTP y el cuerpo de error uniforme. El doble no se expone en producción y no se añade una ruta artificial.

### BR-07 — Persistencia y límites de esta versión

Los datos se mantienen en memoria y no se garantizan tras reiniciar el proceso. Esta versión no incluye autenticación, persistencia, idempotencia ni detección de duplicados. `source` permanece como texto libre.

## Validación por operación

### Crear — `POST /leads`

- Exigir un objeto JSON con solo `name` y `source`.
- Exigir ambos campos como cadenas; aplicar `trim`, contar puntos de código Unicode del resultado y validar los límites de BR-01.
- Rechazar `id`, `status`, `score` y cualquier propiedad no documentada.
- Generar `id`; establecer `status: new` y `score: 0`.
- Responder `201 Created` con el lead creado.

### Asignar score — `POST /leads/{id}/score`

- Exigir ID de ruta no vacío y un objeto JSON que contenga solo `score`.
- Exigir score entero en el rango de BR-03.
- Si el lead no existe, responder `404` según BR-06.
- Si existe, guardar el score y recalcular estado según BR-04 y BR-05.
- Responder `200 OK` con el lead actualizado.

## Trazabilidad

| Requisito | Regla(s) |
|---|---|
| FR-01 | BR-01, BR-02 |
| FR-02 | BR-03, BR-04, BR-05 |
| FR-03 | BR-01, BR-02, BR-03, BR-06 |
| FR-04 | BR-06 |
| FR-05 | BR-06 |
| NFR-01 | BR-01–BR-07 |
| Restricciones y exclusiones | BR-07 |
