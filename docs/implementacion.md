# Plan de Implementación: Migración a Angular Alineada al Backend

Este documento describe los pasos detallados para migrar el proyecto web actual (basado en HTML puro, CSS y JavaScript) a una aplicación **Angular**, asegurando que su estructura y arquitectura reflejen y se conecten perfectamente con el backend existente en ASP.NET Core (`ValleNatural`).

---

## Fases de Implementación

### Fase 1: Preparación y Arquitectura del Proyecto
1. **Creación del Proyecto**: Generar un nuevo espacio de trabajo en Angular.
   ```bash
   ng new valle-natural-app --routing=true --style=css
   ```
2. **Estructura Espejo al Backend**: Organizaremos `src/app` para que la separación de responsabilidades sea idéntica a tu backend en .NET:
   - `/models`: Replicará tus clases de `Models` del backend (ej. `Producto.ts` será el reflejo de `Producto.cs`).
   - `/services`: Replicará la lógica de conexión (en lugar de `FirebaseProductsService.cs`, tendremos un `ProductService.ts` que consumirá los endpoints del `ProductosApiController`).
   - `/pages` (y `/components`): Actuarán como tu capa de `Views`, con componentes inteligentes que orquestarán la información visual.

### Fase 2: Definición de Modelos (Models)
1. Crear las interfaces en TypeScript que coincidan exactamente con la estructura de tu backend.
   ```bash
   ng generate interface models/producto
   ```
   *Esto garantizará que los datos que vengan de tu backend ASP.NET Core coincidan en tipo y propiedades en el frontend.*

### Fase 3: Integración de Servicios (Services)
En lugar de manejar la data quemada en JSON (como se pensaba inicialmente), el frontend consumirá directamente la API construida en tu backend.
1. Habilitar `HttpClientModule` en `app.module.ts`.
2. Generar el servicio principal de productos:
   ```bash
   ng generate service services/product
   ```
3. Dentro de `product.service.ts`, configurar los llamados HTTP (`GET`, `POST`, `PUT`, `DELETE`) apuntando a la ruta de tu `ProductosApiController` (ej. `http://localhost:5000/api/productos`).

### Fase 4: Migración de las Vistas a Componentes
Tal como tu backend tiene controladores (ej. `HomeController`, `AdminController`), estructuraremos nuestras páginas en Angular para responder a esos dominios.

1. **Página de Inicio**:
   ```bash
   ng generate component pages/home
   ```
   Copiar la estructura del inicio estático actual, limpiando la lógica JS.

2. **Panel de Administración**:
   Conectado conceptualmente a tu `AdminController.cs`.
   ```bash
   ng generate component pages/admin
   ```
   Aquí se consumirán los endpoints protegidos para crear, actualizar o eliminar productos.

3. **Página General y Detalles de Producto**:
   ```bash
   ng generate component pages/products
   ng generate component pages/product-detail
   ```
   En lugar de tener más de 30 HTML individuales, `product-detail` usará el "id" del producto en la URL para hacer un `GET` a tu API y mostrar la información dinámicamente.

### Fase 5: Migración de Componentes Compartidos y Assets
1. Generar **Header** y **Footer**:
   ```bash
   ng generate component components/header
   ng generate component components/footer
   ```
2. Mover la carpeta de imágenes actual (`img/`) a `src/assets/img/` dentro de Angular. De esta manera, el frontend servirá sus propios recursos visuales estáticos mientras el backend provee los datos de negocio.
3. Copiar y adaptar `assets/css/style.css` en `src/styles.css`.

### Fase 6: Configuración del Enrutamiento (Routing)
El ruteo del frontend reflejará las rutas de los controladores:
```typescript
const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'productos', component: ProductsComponent },
  { path: 'producto/:id', component: ProductDetailComponent },
  { path: 'admin', component: AdminComponent }, // Interfaz gráfica para AdminController
  { path: '**', redirectTo: '', pathMatch: 'full' }
];
```

### Fase 7: Pruebas y Conexión End-to-End
1. Levantar el proyecto backend de ASP.NET Core (`ValleNatural.sln`) en el puerto por defecto (ej. `https://localhost:5001`).
2. Levantar el proyecto Angular (`ng serve`) y configurar los CORS en el backend si es necesario, para asegurar la comunicación fluida entre el frontend en Angular y la API en C#.

---

## Recomendaciones y Beneficios
* **Consistencia Total**: Al tener `/models` en Angular que son copias exactas de los `Models` en C#, evitarás bugs por falta de coincidencia de campos.
* **Separación Real**: Tu .NET se encargará exclusivamente de procesar reglas de negocio y hablar con Firebase (`FirebaseProductsService`), mientras Angular maneja exclusivamente el DOM y la UX.
* **Mantenibilidad**: Si en el futuro cambias algo en el `ProductosApiController`, sabrás inmediatamente que debes actualizar tu `ProductService.ts` en Angular.
