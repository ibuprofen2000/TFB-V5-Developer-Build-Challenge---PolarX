/**
 * TFB Parking — NUI Application Script
 *
 * Communicates with FiveM via:
 *   window.addEventListener('message', ...)       ← Lua → NUI
 *   fetch('https://tfb-parking/<callback>', ...)   ← NUI → Lua
 */

'use strict';

// ─────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────
const state = {
    garageId:  null,
    vehicles:  [],
    maxSlots:  10,
};

// ─────────────────────────────────────────────
//  DOM references
// ─────────────────────────────────────────────
const app            = document.getElementById('app');
const garageTitle    = document.getElementById('garageTitle');
const garageSubtitle = document.getElementById('garageSubtitle');
const vehicleList    = document.getElementById('vehicleList');
const emptyState     = document.getElementById('emptyState');
const slotCount      = document.getElementById('slotCount');
const btnClose       = document.getElementById('btnClose');
const btnPark        = document.getElementById('btnPark');
const panelParked    = document.getElementById('panelParked');
const panelPark      = document.getElementById('panelPark');
const toast          = document.getElementById('toast');
const tabs           = document.querySelectorAll('.tab');

// ─────────────────────────────────────────────
//  NUI → Lua bridge
// ─────────────────────────────────────────────

/**
 * Send a NUI callback to the Lua resource.
 * @param {string} action - callback name registered with RegisterNUICallback
 * @param {object} data
 * @returns {Promise<any>}
 */
async function nuiPost(action, data = {}) {
    try {
        const res = await fetch(`https://tfb-parking/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
        });
        return await res.json();
    } catch (err) {
        console.error('[tfb-parking] NUI post failed:', action, err);
    }
}

// ─────────────────────────────────────────────
//  Toast notifications
// ─────────────────────────────────────────────
let toastTimer = null;

function showToast(msg, type = 'info') {
    toast.textContent = msg;
    toast.className   = `toast toast--${type} show`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// ─────────────────────────────────────────────
//  Open / close garage UI
// ─────────────────────────────────────────────
function openGarage(garageId, garageLabel, vehicles) {
    state.garageId = garageId;
    state.vehicles = vehicles;

    garageTitle.textContent    = garageLabel;
    garageSubtitle.textContent = `${vehicles.length} vehicle${vehicles.length !== 1 ? 's' : ''} stored`;

    renderVehicleList();
    updateSlotCounter();
    switchTab('parked');

    app.classList.remove('hidden');
}

function closeGarage() {
    app.classList.add('hidden');
    nuiPost('closeGarage');
}

// ─────────────────────────────────────────────
//  Tab switching
// ─────────────────────────────────────────────
function switchTab(tabName) {
    tabs.forEach(t => {
        const active = t.dataset.tab === tabName;
        t.classList.toggle('tab--active', active);
        t.setAttribute('aria-selected', String(active));
    });
    panelParked.classList.toggle('hidden', tabName !== 'parked');
    panelPark.classList.toggle('hidden',   tabName !== 'park');
}

tabs.forEach(t => t.addEventListener('click', () => switchTab(t.dataset.tab)));

// ─────────────────────────────────────────────
//  Slot counter
// ─────────────────────────────────────────────
function updateSlotCounter() {
    slotCount.textContent = `${state.vehicles.length} / ${state.maxSlots} slots used`;
}

// ─────────────────────────────────────────────
//  Vehicle list rendering
// ─────────────────────────────────────────────

/**
 * Return a health bar element filled to `pct` percent.
 * @param {string} label
 * @param {number} pct  0-100
 */
function makeHealthBar(label, pct) {
    pct = Math.max(0, Math.min(100, Math.round(pct)));
    let fillClass = 'hbar__fill--good';
    if (pct < 60) fillClass = 'hbar__fill--medium';
    if (pct < 30) fillClass = 'hbar__fill--bad';

    return `
        <div class="hbar">
            <span class="hbar__label">${escapeHtml(label)}</span>
            <div class="hbar__track">
                <div class="hbar__fill ${fillClass}" style="width:${pct}%"></div>
            </div>
        </div>`;
}

/**
 * Format a UTC date string to a human-readable relative string.
 * @param {string} dateStr
 */
function formatDate(dateStr) {
    if (!dateStr) return '';
    const d    = new Date(dateStr.replace(' ', 'T') + 'Z');
    if (isNaN(d)) return dateStr;
    const diff = Math.floor((Date.now() - d.getTime()) / 1000);
    if (diff < 60)   return 'just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
}

/** Minimal HTML escaping to prevent XSS in rendered content */
function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function renderVehicleList() {
    const vehicles = state.vehicles;

    vehicleList.innerHTML = '';

    if (vehicles.length === 0) {
        emptyState.classList.remove('hidden');
        return;
    }
    emptyState.classList.add('hidden');

    vehicles.forEach((veh, index) => {
        const props       = veh.props || {};
        const modelName   = escapeHtml(props.modelName || veh.model || 'Unknown');
        const plate       = escapeHtml(veh.plate || props.plate || '—');
        const parkedAt    = formatDate(veh.parkedAt);
        const bodyPct     = typeof props.bodyHealth   === 'number' ? (props.bodyHealth   / 1000) * 100 : 100;
        const enginePct   = typeof props.engineHealth === 'number' ? (props.engineHealth / 1000) * 100 : 100;

        const li = document.createElement('li');
        li.className = 'veh-card';
        li.style.animationDelay = `${index * 40}ms`;
        li.innerHTML = `
            <span class="veh-card__name">${modelName}</span>
            <div class="veh-card__meta">
                <span class="badge badge--plate">${plate}</span>
                ${parkedAt ? `<span class="badge badge--date">Parked ${escapeHtml(parkedAt)}</span>` : ''}
            </div>
            <div class="veh-card__actions">
                <button class="btn btn--retrieve js-retrieve" data-id="${veh.id}" aria-label="Retrieve ${modelName}">
                    Retrieve
                </button>
            </div>
            <div style="grid-column:1;grid-row:3" class="health-bars">
                ${makeHealthBar('Body', bodyPct)}
                ${makeHealthBar('Engine', enginePct)}
            </div>`;
        vehicleList.appendChild(li);
    });

    // Event delegation for retrieve buttons
    vehicleList.querySelectorAll('.js-retrieve').forEach(btn => {
        btn.addEventListener('click', () => {
            const vehicleId = parseInt(btn.dataset.id, 10);
            retrieveVehicle(vehicleId);
        });
    });
}

// ─────────────────────────────────────────────
//  Actions
// ─────────────────────────────────────────────
async function retrieveVehicle(vehicleId) {
    if (!state.garageId) return;
    await nuiPost('retrieveVehicle', {
        garageId:  state.garageId,
        vehicleId: vehicleId,
    });
    closeGarage();
}

async function parkVehicle() {
    if (!state.garageId) return;
    await nuiPost('parkVehicle', { garageId: state.garageId });
    // closeGarage is handled server-side via VehicleParked event
}

// ─────────────────────────────────────────────
//  Button listeners
// ─────────────────────────────────────────────
btnClose.addEventListener('click', closeGarage);
btnPark.addEventListener('click', parkVehicle);

// ─────────────────────────────────────────────
//  Keyboard: Escape closes the menu
// ─────────────────────────────────────────────
window.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !app.classList.contains('hidden')) {
        closeGarage();
    }
});

// ─────────────────────────────────────────────
//  Lua → NUI message handler
// ─────────────────────────────────────────────
window.addEventListener('message', e => {
    const { action, garage, vehicles, maxSlots } = e.data || {};

    switch (action) {
        case 'openGarage':
            if (maxSlots) state.maxSlots = maxSlots;
            openGarage(
                garage?.id    ?? '',
                garage?.label ?? 'Garage',
                Array.isArray(vehicles) ? vehicles : []
            );
            break;

        case 'closeGarage':
            app.classList.add('hidden');
            break;

        case 'notify':
            showToast(e.data.message, e.data.type || 'info');
            break;

        default:
            break;
    }
});
