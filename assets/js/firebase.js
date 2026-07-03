// js/firebase.js  ✅ (corregido y completo)
// - Exporta TODO lo que necesitas en DetalleProducto.html y Productos.html
// - Incluye collection (te faltaba exportarla)
// - Incluye un helper opcional "col" por si prefieres abreviar

import { initializeApp } from "https://www.gstatic.com/firebasejs/12.7.0/firebase-app.js";
import {
  getFirestore,
  collection,
  getDocs,
  getDoc,
  addDoc,
  deleteDoc,
  updateDoc,
  doc,
  serverTimestamp,
  query,
  orderBy
} from "https://www.gstatic.com/firebasejs/12.7.0/firebase-firestore.js";

// ✅ TU CONFIG (pegada tal cual)
const firebaseConfig = {
  apiKey: "AIzaSyCstjkMoVF6HFSgSxdbGdkNBeMPad8EchM",
  authDomain: "vallenatural-f5cf1.firebaseapp.com",
  projectId: "vallenatural-f5cf1",
  storageBucket: "vallenatural-f5cf1.firebasestorage.app",
  messagingSenderId: "221524701260",
  appId: "1:221524701260:web:c89ae51acebb3b9cc984e9",
  measurementId: "G-XJD27NNT64"
};

// ✅ App
export const app = initializeApp(firebaseConfig);

// ✅ Firestore
export const db = getFirestore(app);

// ✅ Colección principal (siempre igual en tu proyecto)
export const productosRef = collection(db, "productos");

// ✅ Helper opcional: col("productos") -> collection(db,"productos")
export const col = (name) => collection(db, name);

// ✅ Exports para usar en cualquier HTML
export {
  // core firestore
  collection,
  doc,

  // lecturas
  getDocs,
  getDoc,

  // escrituras
  addDoc,
  deleteDoc,
  updateDoc,

  // utilidades
  serverTimestamp,
  query,
  orderBy
};
