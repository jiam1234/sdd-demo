Feature: Leads API v2
  Como consumidor de Leads API
  Quiero crear leads y asignarles un score
  Para obtener una clasificación determinista y errores consistentes

  @FR-01 @BR-01 @BR-02 @CA-01
  Scenario: Crear un lead válido
    When envío POST /leads con name "Juan" y source "whatsapp"
    Then recibo HTTP 201
    And la respuesta contiene un id generado por el servidor
    And name es "Juan" y source es "whatsapp"
    And status es "new" y score es 0

  @FR-01 @BR-01
  Scenario: Evaluar la longitud después de trim
    When envío POST /leads con name "  Juan  " y source " whatsapp "
    Then recibo HTTP 201
    And la respuesta contiene name "Juan" y source "whatsapp"

  @FR-01 @FR-03 @BR-01
  Scenario Outline: Aplicar límites por puntos de código Unicode tras normalizar
    When envío POST /leads con name de <name_points> puntos U+1F600 y source de <source_points> puntos U+1F600
    Then recibo HTTP <http_status>
    And si la respuesta es un error, code es "VALIDATION_ERROR" y message no está vacío

    Examples:
      | name_points | source_points | http_status |
      | 1           | 1             | 201 |
      | 100         | 50            | 201 |
      | 101         | 50            | 400 |
      | 100         | 51            | 400 |
      | 0           | 1             | 400 |

  @FR-01 @FR-03 @BR-01 @CA-02
  Scenario Outline: Rechazar name inválido al crear un lead
    When envío POST /leads con body <body>
    Then recibo HTTP 400
    And la respuesta de error tiene code "VALIDATION_ERROR" y message no vacío

    Examples:
      | body |
      | {"source":"whatsapp"} |
      | {"name":"","source":"whatsapp"} |
      | {"name":"   ","source":"whatsapp"} |
      | {"name":123,"source":"whatsapp"} |

  @FR-01 @FR-03 @BR-01 @CA-02
  Scenario Outline: Rechazar source inválido al crear un lead
    When envío POST /leads con body <body>
    Then recibo HTTP 400
    And la respuesta de error tiene code "VALIDATION_ERROR" y message no vacío

    Examples:
      | body |
      | {"name":"Juan"} |
      | {"name":"Juan","source":""} |
      | {"name":"Juan","source":"   "} |
      | {"name":"Juan","source":123} |

  @FR-03 @BR-02 @CA-07
  Scenario Outline: Rechazar campos adicionales al crear un lead
    When envío POST /leads con body <body>
    Then recibo HTTP 400
    And la respuesta de error tiene code "VALIDATION_ERROR" y message no vacío

    Examples:
      | body |
      | {"name":"Juan","source":"whatsapp","id":"cliente"} |
      | {"name":"Juan","source":"whatsapp","status":"vip"} |
      | {"name":"Juan","source":"whatsapp","score":90} |
      | {"name":"Juan","source":"whatsapp","extra":true} |

  @FR-02 @BR-03 @BR-04 @BR-05 @CA-03
  Scenario Outline: Clasificar un lead en los umbrales aprobados
    Given existe un lead creado
    When envío POST /leads/{id}/score con score <score>
    Then recibo HTTP 200
    And la respuesta contiene score <score> y status "<status>"

    Examples:
      | score | status |
      | 0     | new |
      | 70    | new |
      | 71    | qualified |
      | 89    | qualified |
      | 90    | vip |
      | 100   | vip |

  @FR-02 @FR-03 @BR-03 @BR-06 @CA-04
  Scenario Outline: Rechazar score inválido
    Given existe un lead creado
    When envío POST /leads/{id}/score con cuerpo <body>
    Then recibo HTTP 400
    And la respuesta de error tiene code "VALIDATION_ERROR" y message no vacío

    Examples:
      | body |
      | {"score": -1} |
      | {"score": 101} |
      | {} |
      | {"score": 70.5} |
      | {"score": "70"} |
      | {"score": null} |

  @FR-02 @FR-03 @BR-02 @BR-06 @CA-07
  Scenario: Rechazar propiedad adicional al asignar score
    Given existe un lead creado
    When envío POST /leads/{id}/score con {"score": 80, "extra": true}
    Then recibo HTTP 400
    And la respuesta de error tiene code "VALIDATION_ERROR" y message no vacío

  @FR-02 @FR-04 @BR-06 @CA-05
  Scenario: Asignar score a un ID inexistente
    When envío POST /leads/id-inexistente/score con {"score": 80}
    Then recibo HTTP 404
    And la respuesta de error tiene code "LEAD_NOT_FOUND" y message no vacío

  @FR-02 @BR-04 @BR-05 @CA-06
  Scenario: Bajar la clasificación de VIP a new
    Given existe un lead creado
    And asigno score 95 y recibo status "vip"
    When asigno score 70 al mismo lead
    Then recibo HTTP 200
    And la respuesta contiene score 70 y status "new"

  @FR-03 @FR-04 @BR-06 @CA-08
  Scenario Outline: Rechazar tipo de contenido no admitido
    When envío una solicitud a <endpoint> con Content-Type "text/plain"
    Then recibo HTTP 415
    And la respuesta de error tiene code "UNSUPPORTED_MEDIA_TYPE" y message no vacío

    Examples:
      | endpoint |
      | /leads |
      | /leads/{id}/score |

  @FR-03 @FR-04 @BR-06
  Scenario: Rechazar JSON mal formado
    When envío JSON mal formado a POST /leads con Content-Type "application/json"
    Then recibo HTTP 400
    And la respuesta de error tiene code "VALIDATION_ERROR" y message no vacío

  @FR-04 @FR-05 @BR-06 @CA-09
  Scenario: Representar un fallo inesperado provocado por el test harness
    Given existe un lead creado
    And el test harness hace que la actualización del almacenamiento en memoria lance una excepción
    When envío POST /leads/{id}/score con {"score":80}
    Then recibo HTTP 500
    And la respuesta de error tiene code "INTERNAL_ERROR" y message no vacío
