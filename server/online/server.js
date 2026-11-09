// GodotF126 — servidor de salas online de 2 jugadores.
// Un jugador crea una sala con sus reglas (pista, vueltas, clima, neumáticos); los que buscan
// reciben la lista de salas abiertas (actualizada en vivo) y se unen a una. Al unirse, los dos
// reciben "matched" con las reglas de la sala y el servidor reenvía los mensajes de uno al otro.
// Cuando los dos avisan "ready" manda "go" con una semilla común para el semáforo.
// No simula nada: la física corre en la PC de cada jugador.
//
// Uso: node server.js   (escucha en 127.0.0.1:PORT; nginx lo publica en wss://…/ws)

"use strict";
const { WebSocketServer } = require("ws");

const PORT = Number(process.env.PORT || 8765);
const HOST = process.env.HOST || "127.0.0.1";
const PROTOCOL = 2;
const MAX_CLIENTS = 200;
const MAX_ROOMS = 100;
const MAX_MESSAGE = 4096;
const MAX_NAME = 16;
const RELAYED = new Set(["s", "fin", "chat"]);

const wss = new WebSocketServer({ host: HOST, port: PORT, maxPayload: MAX_MESSAGE });
const rooms = new Map();
let nextClient = 1;
let nextRoom = 1;

function send(ws, msg) {
  if (ws && ws.readyState === ws.OPEN) ws.send(JSON.stringify(msg));
}

function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

function text(value, max) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function cleanPlayer(p) {
  p = p && typeof p === "object" ? p : {};
  return {
    name: text(p.name, MAX_NAME) || "Jugador",
    driver_id: text(p.driver_id, 32),
    driver_name: text(p.driver_name, 40),
    team_id: text(p.team_id, 32),
  };
}

function cleanSettings(s) {
  s = s && typeof s === "object" ? s : {};
  const laps = Number(s.laps);
  return {
    track: text(s.track, 32),
    laps: Number.isFinite(laps) ? Math.min(Math.max(Math.round(laps), 1), 20) : 2,
    weather: text(s.weather, 32),
    compound: text(s.compound, 32),
  };
}

function publicRooms() {
  const list = [];
  for (const room of rooms.values()) {
    list.push({ id: room.id, host: room.player.name, driver: room.player.driver_name, ...room.settings });
  }
  return list;
}

function broadcastRooms() {
  const msg = { t: "rooms", rooms: publicRooms() };
  for (const ws of wss.clients) if (ws.browsing) send(ws, msg);
}

function closeRoom(ws) {
  if (ws.room && rooms.get(ws.room.id) === ws.room) {
    rooms.delete(ws.room.id);
    ws.room = null;
    broadcastRooms();
  }
  ws.room = null;
}

function leave(ws, reason) {
  ws.browsing = false;
  closeRoom(ws);
  const peer = ws.peer;
  if (peer) {
    peer.peer = null;
    send(peer, { t: "left", reason });
  }
  ws.peer = null;
}

function versionOk(ws, msg) {
  if (msg.v === PROTOCOL) return true;
  send(ws, { t: "error", reason: "Versión distinta del servidor: actualizá el juego (recargá la página)." });
  return false;
}

wss.on("connection", (ws, req) => {
  if (wss.clients.size > MAX_CLIENTS) {
    ws.close(1013, "lleno");
    return;
  }
  ws.id = nextClient++;
  ws.alive = true;
  ws.on("pong", () => { ws.alive = true; });
  log(`conexión #${ws.id}`, req.headers["cf-connecting-ip"] || req.socket.remoteAddress);

  ws.on("message", (data) => {
    let msg;
    try {
      msg = JSON.parse(data.toString());
    } catch {
      return;
    }
    if (!msg || typeof msg.t !== "string") return;
    if (msg.t === "ping") {
      send(ws, { t: "pong", c: msg.c });
    } else if (msg.t === "list") {
      if (!versionOk(ws, msg)) return;
      ws.browsing = true;
      send(ws, { t: "rooms", rooms: publicRooms() });
    } else if (msg.t === "create") {
      if (!versionOk(ws, msg) || ws.peer || ws.room) return;
      if (rooms.size >= MAX_ROOMS) {
        send(ws, { t: "error", reason: "Hay demasiadas salas abiertas: probá en un rato." });
        return;
      }
      ws.browsing = false;
      ws.ready = false;
      ws.room = { id: nextRoom++, host: ws, player: cleanPlayer(msg.player), settings: cleanSettings(msg.settings) };
      rooms.set(ws.room.id, ws.room);
      send(ws, { t: "created", room: ws.room.id });
      log(`sala ${ws.room.id} de #${ws.id}`, JSON.stringify(ws.room.settings));
      broadcastRooms();
    } else if (msg.t === "join") {
      if (!versionOk(ws, msg) || ws.peer || ws.room) return;
      const room = rooms.get(Number(msg.room));
      if (!room || room.host.readyState !== room.host.OPEN) {
        send(ws, { t: "error", reason: "La sala ya no está disponible: elegí otra." });
        return;
      }
      rooms.delete(room.id);
      const host = room.host;
      host.room = null;
      ws.browsing = false;
      host.peer = ws;
      ws.peer = host;
      host.ready = false;
      ws.ready = false;
      const guest = cleanPlayer(msg.player);
      send(host, { t: "matched", slot: 0, opponent: guest, settings: room.settings });
      send(ws, { t: "matched", slot: 1, opponent: room.player, settings: room.settings });
      log(`sala ${room.id}: #${host.id} + #${ws.id}`);
      broadcastRooms();
    } else if (msg.t === "ready") {
      ws.ready = true;
      if (ws.peer && ws.peer.ready) {
        const go = { t: "go", seed: Math.floor(Math.random() * 1e9) + 1 };
        send(ws, go);
        send(ws.peer, go);
      }
    } else if (msg.t === "leave") {
      leave(ws, "salió");
    } else if (RELAYED.has(msg.t) && ws.peer) {
      send(ws.peer, msg);
    }
  });

  ws.on("close", () => {
    log(`cierre #${ws.id}`);
    leave(ws, "desconectado");
  });
  ws.on("error", () => {});
});

// Corta las conexiones que dejaron de responder (pestaña cerrada sin aviso, red caída).
setInterval(() => {
  for (const ws of wss.clients) {
    if (!ws.alive) {
      ws.terminate();
      continue;
    }
    ws.alive = false;
    ws.ping();
  }
}, 15000);

log(`GodotF126 online en ${HOST}:${PORT} (protocolo ${PROTOCOL})`);
