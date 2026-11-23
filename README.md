# ¿En qué se me fue?

Aplicación web progresiva (PWA) para registrar ingresos y gastos, organizar presupuestos y comprender hábitos de dinero. Interfaz en español y moneda MXN.

## Funciones

- Registro, edición, búsqueda y filtrado de ingresos y gastos.
- Categorías estándar y personalizadas.
- Panel mensual, gráficas, tendencias y comparación con el mes anterior.
- Presupuesto mensual y límites por categoría, con avisos al 50%, 80% y 100%.
- Metas de ahorro con seguimiento.
- Control de deudas y abonos.
- Pagos recurrentes: recordatorios, notificaciones y acción para marcar un pago como realizado; esta acción registra el gasto y avanza la próxima fecha, no realiza cargos bancarios.
- Calendario de movimientos.
- Respaldo JSON y restauración combinada para evitar borrar movimientos actuales.
- Exportación CSV, libro Excel y reporte imprimible que puede guardarse como PDF.
- Escáner OCR de tickets mediante Tesseract.js; requiere cargar la librería y revisar manualmente el importe/fecha detectados.
- Asistente financiero: análisis local básico sin conexión y respuestas generativas opcionales mediante una función segura de Supabase.
- Modo claro/oscuro y temas de color.
- Guardado local primero y sincronización con Supabase al recuperar conexión.
- Acceso directo con sesión anónima; no solicita correo ni contraseña.

## Publicación

GitHub Pages se publica desde la rama `main` y la carpeta raíz.

Dirección: https://juanangelbustos481-star.github.io/en-que-se-me-fue/

## Configuración de Supabase

1. Habilita **Anonymous Sign-ins** en Authentication > Providers.
2. Ejecuta el SQL de `supabase/migrations/202611230001_public_anon_user_data.sql` en el SQL Editor. La migración es aditiva, conserva los registros existentes y agrega políticas que limitan cada fila a `auth.uid() = user_id`.
3. La tabla `public.user_app_data` conserva un documento JSON por usuario anónimo. No deshabilites RLS ni crees políticas públicas sin filtro de propietario.
4. Los datos de sesiones con cuenta creadas antes de habilitar el acceso anónimo no se eliminan. Una sesión anónima nueva tiene otro identificador; conserva una copia de respaldo de los datos de cuentas antiguas antes de dejar de utilizar esas cuentas.

## Activar respuestas generativas del asistente

La aplicación ya incluye un análisis local sin conexión. Para habilitar respuestas generativas:

1. Despliega `supabase/functions/financial-assistant/index.ts` como Edge Function llamada `financial-assistant`.
2. Configura el secreto del servidor `OPENAI_API_KEY` en Supabase. Opcionalmente define `OPENAI_MODEL`.
3. Nunca pegues la clave de OpenAI en `index.html), JavaScript del navegador o repositorios públicos.
4. Si la función no está desplegada o falta el secreto, el asistente continúa usando el análisis local.

La función envía al modelo únicamente datos agregados (totales, categorías, metas y próximos pagos), no descripciones ni notas de los movimientos.

## Modo sin conexión y respaldo

Los cambios se guardan primero en el navegador. Cuando hay conexión y una sesión anónima válida, se sincronizan con Supabase. El navegador debe conservar sus datos del sitio para mantener el acceso a la copia local y a la sesión anónima. Si se borran los datos del navegador o se cambia de dispositivo, la sesión anónima puede no recuperarse. Descarga respaldos JSON con regularidad y guárdalos en un lugar seguro.

El reconocimiento OCR y la exportación XLSX cargan librerías externas cuando se usan; esas dos operaciones necesitan conexión. La exportación CSV y el registro básico siguen disponibles sin conexión.

## Privacidad

Los datos financieros pertenecen al usuario que mantiene la sesión anónima en ese navegador. No introduzcas contraseñas bancarias, números de tarjeta ni datos personales sensibles. Las notificaciones dependen del permiso del navegador. Los pagos recurrentes son recordatorios y no autorizan ni ejecutan cargos.
