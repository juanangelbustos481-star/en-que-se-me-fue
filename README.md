# ¿En qué se me fue?

Aplicación web progresiva (PWA) para llevar un registro personal de ingresos, gastos y metas de dinero.

## Funciones
- Registro, edición y eliminación de ingresos y gastos.
- Categorías con iconos y colores.
- Resumen mensual: saldo, ingresos, gastos y promedio.
- Gráfica de distribución de gastos.
- Presupuesto mensual y límites por categoría.
- Búsqueda y filtros de movimientos.
- Calendario para consultar movimientos por fecha.
- Metas de ahorro con seguimiento de avance.
- Registro de deudas y abonos.
- Recordatorios de pagos recurrentes (no realiza cargos automáticos).
- Exportación de movimientos a CSV e impresión del resumen para guardarlo como PDF.
- Modo claro y oscuro.
- Diseño adaptable a celulares y computadoras.
- Almacenamiento local y caché para uso básico sin conexión después de la primera visita.

## Publicación
El sitio se publica con GitHub Pages desde la rama `main` y la carpeta `/(root)`.

Dirección: https://juanangelbustos481-star.github.io/en-que-se-me-fue/

## Privacidad y almacenamiento
La aplicación crea una sesión anónima automática con Supabase: no solicita correo ni contraseña. Los movimientos, presupuestos, metas, deudas y recordatorios se guardan en la nube asociados al identificador anónimo de cada navegador, con políticas RLS para separar los datos de cada visitante. Si se borran los datos del navegador o se cambia de dispositivo, la sesión anónima puede perderse y no será posible recuperar esos datos; descarga periódicamente un respaldo desde la aplicación. El proyecto debe tener habilitados los inicios de sesión anónimos en Supabase.
