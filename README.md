# Controla – Gestión de Negocios

Aplicación independiente para pequeños comercios. Interfaz web adaptable a móviles.

## Incluye en esta primera entrega
- Registro de cuenta e inicio de sesión con Supabase Auth.
- Espacio privado por negocio y aislamiento con Row Level Security (RLS).
- Inventario manual e importación CSV (Excel puede exportarse como CSV UTF-8).
- Registro de ventas con método de pago y descuento de existencias.
- Gastos y compras con adjunto de foto/archivo de recibo.
- Personal, servicios y cálculo de comisión para salones.
- Resumen diario y reporte por periodo exportable a CSV.

## Publicación
GitHub Pages sirve el frontend estático. Repositorio: https://github.com/Jaime010878/controla-gestion-negocios

## Configuración Supabase
1. Crea un proyecto Supabase en la región South America (São Paulo), plan acorde a tus necesidades.
2. En SQL Editor ejecuta el contenido completo de `supabase/schema.sql`.
3. En Project Settings > API copia Project URL y la clave publicable (publishable/anon). Nunca uses `service_role` ni una secret key en el navegador.
4. Abre Controla, pega URL y clave pública en la pantalla inicial.
5. Configura Auth > URL Configuration con la URL de GitHub Pages y confirma el correo de registro.
6. Prueba con dos cuentas distintas y confirma que una no puede consultar los datos de la otra.

La contraseña de base de datos no se usa en el frontend ni se debe incluir en este repositorio.

## Limitaciones conocidas de esta versión
- La foto del recibo se adjunta al gasto; la extracción automática de texto (OCR) aún requiere un proveedor OCR.
- La carga inicial de productos admite CSV; XLSX nativo, lector de códigos de barras, facturación electrónica e integración DIAN no están incluidos.
- El resumen de utilidad es estimado y no es contabilidad tributaria certificada.
- El control de inventario y venta está implementado como flujo básico; antes de producción comercial debe añadirse edición de registros, reversos/auditoría y pruebas de concurrencia.
