# Qué le falta a la app — recomendaciones priorizadas

Orden por impacto real sobre la población que acompaña Revive tu Espacio, no por qué tan atractivo se ve en una demo. Lo primero de la lista es lo que decide si la herramienta se usa o se abandona.

---

## Prioridad 1 — Lo que decide si la gente sigue capturando

**1. Gastos recurrentes con un toque.** La renta, el gas, el pasaje diario. Que la persona los marque una vez como plantilla y después los registre con un botón, sin volver a escribir monto ni categoría. La captura repetitiva es la razón número uno por la que se abandona una app de gastos.

**2. Recordatorio diario de captura.** Una notificación a la hora que la persona elija. Técnicamente exige convertir la app en PWA con service worker y permiso de notificaciones; en iPhone solo funciona si está instalada en la pantalla de inicio, lo cual refuerza que la instalación sea obligatoria en la sesión de alta.

**3. Captura por voz.** El campo de monto y nota con dictado. Para quien escribe lento en el teléfono —que en esta población es mucha gente— la diferencia entre diez segundos y cuarenta define si lo anota o no.

**4. Modo de captura rápida sin abrir la app.** Un acceso directo desde la pantalla de inicio que abra ya en la pantalla de monto. Se implementa con `shortcuts` en el manifiesto.

---

## Prioridad 2 — Lo que convierte el registro en decisiones

**5. Fondo de emergencia como meta especial.** Con la referencia de tres a seis meses de gastos esenciales, calculada con las cifras reales de la persona. Es la única defensa contra volver a endeudarse ante un imprevisto, y hoy la app no lo distingue de cualquier otra meta.

**6. Simulador de crédito antes de contratarlo.** "Si tomo un préstamo de X a N meses, ¿cómo queda mi capacidad?" Enseña el pago mensual, el costo total en intereses y si rebasa el 30%. Esto es prevención, no diagnóstico, y encaja perfecto con la misión de la asociación.

**7. Calculadora de CAT y comparador.** Que la persona capture la oferta que le hicieron y vea el costo real. Muchos créditos de barrio y de apps se contratan sin saber la tasa anualizada.

**8. Proyección de fin de periodo.** "Al ritmo que vas, vas a terminar con un faltante de X." Aviso mientras todavía se puede corregir, no el reporte al final cuando ya no sirve.

**9. Comparativo de varios periodos.** Una gráfica de los últimos seis periodos por categoría. Un gasto suelto no dice nada; la tendencia sí.

---

## Prioridad 3 — Realidades de esta población que las apps comerciales ignoran

**10. Gasto compartido de hogar.** Muchas familias reparten renta y despensa entre varias personas. Poder marcar un gasto como compartido y registrar solo la parte propia.

**11. Dinero prestado a terceros.** Prestarle a un familiar es un flujo constante en economías de bajos ingresos y hoy se registra como "gasto", lo cual distorsiona todo. Debería ser una cuenta por cobrar.

**12. Tandas.** Es el instrumento de ahorro más usado en México y ninguna app comercial lo modela. Aportación periódica, número de la persona en la lista, mes en que le toca cobrar. Sería un diferenciador real de esta herramienta.

**13. Ingresos irregulares.** Quien vende en la calle o trabaja por día no tiene un ingreso fijo. Un promedio móvil con rango bajo–alto sirve más que un número único, y el ciclo diario que ya se agregó es el primer paso.

**14. Modo acompañante.** Un promotor con varios perfiles en la misma tableta, cada uno separado. Ya está previsto en el diseño pero no implementado.

---

## Prioridad 4 — Confianza y continuidad

**15. Bloqueo con PIN o huella.** Un teléfono prestado o compartido es la norma, no la excepción. Sin esto, cualquiera que tome el teléfono ve las deudas de la persona.

**16. Respaldo automático a un archivo.** Hoy depende de que la persona se acuerde. Un recordatorio programado ayuda; la solución real es la sincronización.

**17. Sincronización opcional con Supabase.** Ya está el esquema listo. Debe ser opt-in explícito y con RLS estricta: la asociación no debe poder ver los datos.

---

## Lo que recomiendo NO construir

**Conexión automática al banco.** Suena como la mejora obvia y es la peor idea de la lista. Exige un agregador financiero, credenciales bancarias y responsabilidad legal sobre datos sensibles que la asociación no está en condiciones de asumir. Además, buena parte de esta población opera en efectivo, así que ni siquiera resolvería el problema.

**Gamificación con rachas y trofeos.** Funciona en apps de idiomas. En finanzas de subsistencia, romper una racha en una semana mala se siente como un reproche, y la persona deja de abrir la app justo cuando más la necesita.

**Recomendaciones de productos financieros.** El momento en que una herramienta de una asociación civil empieza a sugerir créditos es el momento en que pierde la autoridad moral que la hace útil. Aunque no haya comisión de por medio.

---

## Sobre los umbrales de endeudamiento que ya quedaron implementados

La app calcula la capacidad tomando el criterio más conservador entre dos:

- **30% del dinero disponible** una vez cubiertos los gastos esenciales. La Asociación de Bancos de México recomienda que el pago de deudas quede entre 30% y 40% de ese remanente; se toma el extremo bajo.
- **30% del ingreso neto mensual.** Es el umbral que la educación financiera de Banxico ubica como frontera de una carga de deuda alta.

La lectura del semáforo:

| Pago de deuda sobre ingreso | Diagnóstico |
|---|---|
| Hasta 30% | Nivel sano |
| 31% a 40% | Zona de vigilancia — todavía hay margen de corrección |
| Más de 40% | Sobreendeudamiento — cualquier imprevisto se cubre con más deuda |

Se usa el ingreso registrado cuando hay al menos 30 días de historial; con menos, manda el ingreso que la persona declaró, porque extrapolar tres días a un mes produce cifras sin sentido.
