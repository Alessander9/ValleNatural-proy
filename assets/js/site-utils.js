export function escapeHtml(str) {
  return String(str).replace(/[&<>"']/g, m => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;"
  }[m]));
}

export function toNumberSafe(v) {
  const n = Number(String(v ?? "0").replace(",", "."));
  return Number.isFinite(n) ? n : 0;
}

export function buildWhatsAppUrl(phone, message) {
  return `https://wa.me/${phone}?text=${encodeURIComponent(message)}`;
}

export function prettyCategory(cat) {
  const map = {
    "frutos_secos":"Frutos secos",
    "semillas":"Semillas",
    "granos_pops":"Granos / Pops",
    "superfoods_suplementos":"Superfoods / Suplementos",
    "endulzantes_infusiones":"Endulzantes e infusiones",
    "aceites":"Aceites",
    "medicinales":"Plantas Medicinales",
    "snacks":"Snacks saludables",
    "colageno":"Colágeno",
    "vitaminas-suplementos":"Vitaminas / Suplementos"
  };
  return map[String(cat || "").toLowerCase()] || (cat || "-");
}
