// js/products-store.js
const LS_KEY = "vn_products_v1";

/**
 * Categorías basadas en tu PDF:
 * 1) Mieles y Endulzantes Naturales
 * 2) Superalimentos del Perú
 * 3) Frutos Secos y Semillas
 * 4) Harinas, Granos y Cereales
 * 5) Aceites Naturales
 * 6) Colágenos y Articulaciones
 * 7) Vitaminas, Minerales y Suplementos
 * 8) Plantas Medicinales y Extractos
 * 9) Infusiones, Snacks y Mezclas Funcionales
 */
export const CATEGORIES = [
  // value = key que se usará para filtrar en Productos.html (data-cat)
  { value: "endulzantes_infusiones", label: "Mieles y Endulzantes Naturales" },
  { value: "superfoods_suplementos", label: "Superalimentos del Perú" },
  { value: "frutos_secos", label: "Frutos Secos y Semillas" },
  { value: "granos_pops", label: "Harinas, Granos y Cereales" },
  { value: "aceites", label: "Aceites Naturales" },
  { value: "superfoods_suplementos", label: "Colágenos y Articulaciones" },
  { value: "superfoods_suplementos", label: "Vitaminas, Minerales y Suplementos" },
  { value: "superfoods_suplementos", label: "Plantas Medicinales y Extractos" },
  { value: "endulzantes_infusiones", label: "Infusiones, Snacks y Mezclas Funcionales" },
];

export function getAdminProducts() {
  try {
    return JSON.parse(localStorage.getItem(LS_KEY)) ?? [];
  } catch {
    return [];
  }
}

function save(list) {
  localStorage.setItem(LS_KEY, JSON.stringify(list));
}

export function addProduct(p) {
  const list = getAdminProducts();
  list.unshift(p);
  save(list);
}

export function updateProduct(id, partial) {
  const list = getAdminProducts();
  const idx = list.findIndex(x => x.id === id);
  if (idx === -1) return false;
  list[idx] = { ...list[idx], ...partial };
  save(list);
  return true;
}

export function deleteProduct(id) {
  const list = getAdminProducts().filter(x => x.id !== id);
  save(list);
}

export function clearProducts() {
  localStorage.removeItem(LS_KEY);
}
