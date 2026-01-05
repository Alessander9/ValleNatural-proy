// js/firebase.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/12.7.0/firebase-app.js";
import {
  getFirestore,
  collection,
  getDocs,
  addDoc,
  getDoc,
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

const app = initializeApp(firebaseConfig);

// ✅ Firestore
export const db = getFirestore(app);

// ✅ Colección principal
export const productosRef = collection(db, "productos");

// Helpers exportados
export {
  getDocs,
  getDoc,
  addDoc,
  deleteDoc,
  updateDoc,
  doc,
  serverTimestamp,
  query,
  orderBy
};
