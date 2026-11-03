// Saves the port and token for the WebSocket to the Cumba app.
"use strict";

// The page's text in the app's languages. Spanish for Spain says "Ajustes" like macOS there;
// every other Spanish uses the Latin American "Configuración".
const STRINGS = {
  en: {
    hint: "Copy the port and token from Cumba > Settings > Connections.",
    port: "Port",
    token: "Token",
    save: "Save",
    saved: "Saved.",
    invalid: "Invalid port or token.",
    connected: "Connected to the app.",
    connecting: "Connecting…",
    unreachable: "Can't reach the app.",
    disconnected: "Not connected.",
    noToken: "No token yet.",
  },
  tr: {
    hint: "Portu ve token'ı Cumba > Ayarlar > Bağlantılar bölümünden kopyalayın.",
    port: "Port",
    token: "Token",
    save: "Kaydet",
    saved: "Kaydedildi.",
    invalid: "Geçersiz port veya token.",
    connected: "Uygulamaya bağlı.",
    connecting: "Bağlanıyor…",
    unreachable: "Uygulamaya ulaşılamıyor.",
    disconnected: "Bağlı değil.",
    noToken: "Token girilmedi.",
  },
  es: {
    hint: "Copia el puerto y el token desde Cumba > Ajustes > Conexiones.",
    port: "Puerto",
    token: "Token",
    save: "Guardar",
    saved: "Guardado.",
    invalid: "El puerto o el token no son válidos.",
    connected: "Conectado a la app.",
    connecting: "Conectando…",
    unreachable: "No se puede conectar con la app.",
    disconnected: "Sin conexión.",
    noToken: "Aún no hay token.",
  },
  fr: {
    hint: "Copiez le port et le jeton depuis Cumba > Réglages > Connexions.",
    port: "Port",
    token: "Jeton",
    save: "Enregistrer",
    saved: "Enregistré.",
    invalid: "Port ou jeton non valide.",
    connected: "Connecté à l’app.",
    connecting: "Connexion…",
    unreachable: "Impossible de joindre l’app.",
    disconnected: "Non connecté.",
    noToken: "Aucun jeton pour l’instant.",
  },
};
STRINGS["es-419"] = {
  ...STRINGS.es,
  hint: "Copia el puerto y el token desde Cumba > Configuración > Conexiones.",
};

function language(tag) {
  const [base, region] = tag.toLowerCase().split("-");
  if (base === "es") {
    return region === undefined || region === "es" ? "es" : "es-419";
  }
  return base in STRINGS ? base : "en";
}

const LANGUAGE = language(navigator.language);
const TEXT = STRINGS[LANGUAGE];
document.documentElement.lang = LANGUAGE;

for (const element of document.querySelectorAll("[data-i18n]")) {
  element.textContent = TEXT[element.dataset.i18n];
}

const port = document.getElementById("port");
const token = document.getElementById("token");
const status = document.getElementById("status");

async function showStatus() {
  try {
    const response = await chrome.runtime.sendMessage({ type: "getStatus" });
    status.textContent = TEXT[response && response.status] || "";
  } catch {
    status.textContent = "";
  }
}

chrome.storage.local.get(["port", "token"]).then((values) => {
  if (values.port) {
    port.value = values.port;
  }
  if (values.token) {
    token.value = values.token;
  }
  showStatus();
});

document.getElementById("save").addEventListener("click", async () => {
  const portValue = Number(port.value);
  const tokenValue = token.value.trim();
  if (!Number.isInteger(portValue) || portValue < 1024 || portValue > 65535
    || !/^[0-9a-f]{64}$/.test(tokenValue)) {
    status.textContent = TEXT.invalid;
    return;
  }
  await chrome.storage.local.set({ port: portValue, token: tokenValue });
  status.textContent = TEXT.saved;
  setTimeout(showStatus, 1500);
});
