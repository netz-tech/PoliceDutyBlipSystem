const menuEl = document.getElementById('duty-menu');
const optionsEl = document.getElementById('menu-options');
const DEFAULT_RESOURCE = 'PoliceDuty+BlipSystem';
const parentResource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
const resourceName = parentResource || DEFAULT_RESOURCE;
const assetBase = parentResource ? `nui://${resourceName}/ui` : '';
let menuVisible = false;

const ICON_FALLBACKS = ['PD', 'FED', 'OPS', 'FRE', 'INT', 'SPEC'];
const iconMap = {
    DEFAULT: 'images/departments/default.png', // DO NOT CHANGE THIS (You can change the default.png file to whatever you want the default icon to be, but keep the name as default.png or update the DEFAULT key here to match the filename you choose)
    OFF_DUTY: 'images/off-duty.png', // This is the icon used for the "off duty" option, you can change this to whatever you want as well, just update the OFF_DUTY key here to match the filename
    YOURDEPARTMENT: 'images/departments/YourDepartment.png', // Whatever departments you want to have custom icons for, add them here with the key matching the department name in config.lua
};
const defaultIconSrc = resolveAsset(iconMap.DEFAULT);
const offDutyIconSrc = resolveAsset(iconMap.OFF_DUTY);

function resolveAsset(relativePath) {
    if (!relativePath) {
        return '';
    }

    return assetBase ? `${assetBase}/${relativePath}` : relativePath;
}

function getDepartmentIcon(deptKey) {
    if (!deptKey) {
        return defaultIconSrc;
    }

    const key = deptKey.toUpperCase();
    const override = iconMap[key];
    if (override) {
        return resolveAsset(override);
    }

    return resolveAsset(`images/departments/${key}.png`);
}

function buildImageTag(src, altText) {
    const safeAlt = altText || 'Dept';
    return `<img src="${src}" alt="${safeAlt}" onerror="this.onerror=null;this.src='${defaultIconSrc}';" />`;
}

function getIconMarkup(item, index) {
    if (item.action === 'off') {
        return buildImageTag(offDutyIconSrc, 'Off Duty');
    }

    const deptKey = (item.department || '').toUpperCase();
    const iconSrc = getDepartmentIcon(deptKey);
    if (iconSrc) {
        return buildImageTag(iconSrc, deptKey || 'Dept');
    }

    return `<span>${ICON_FALLBACKS[index % ICON_FALLBACKS.length]}</span>`;
}

function sendNuiCallback(route, payload = {}) {
    try {
        fetch(`https://${resourceName}/${route}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload)
        }).catch(() => {});
    } catch (err) {
        console.error('Duty menu NUI callback failed:', err);
    }
}

function buildOptions(data) {
    optionsEl.innerHTML = '';
    data.forEach((item, idx) => {
        const option = document.createElement('div');
        option.className = 'option';
        option.dataset.action = item.action;
        if (item.department) {
            option.dataset.department = item.department;
        }

        const iconMarkup = getIconMarkup(item, idx);

        option.innerHTML = `
            <div class="option-left">
                <div class="option-icon">${iconMarkup}</div>
                <div class="option-text">
                    <div class="option-label">${item.label}</div>
                    <div class="option-desc">${item.description}</div>
                </div>
            </div>
            <div class="option-right">
                <div class="option-action">SELECT</div>
                <div class="chevron">&gt;</div>
            </div>
        `;

        option.addEventListener('click', () => {
            sendNuiCallback('dutyMenuSelect', {
                action: option.dataset.action,
                department: option.dataset.department || null
            });
            closeMenu();
        });

        optionsEl.appendChild(option);
    });
}

function openMenu(payload) {
    buildOptions(payload.options || []);
    menuVisible = true;
    menuEl.classList.add('show');
    menuEl.classList.remove('hidden');
}

function closeMenu(notifyServer = true) {
    if (!menuVisible) return;
    menuVisible = false;
    menuEl.classList.remove('show');
    setTimeout(() => menuEl.classList.add('hidden'), 150);
    if (notifyServer) {
        sendNuiCallback('dutyMenuClose', {});
    }
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'openDutyMenu') {
        openMenu(data.payload || {});
    } else if (data.action === 'closeDutyMenu') {
        closeMenu(false);
    }
});

document.addEventListener('keydown', (event) => {
    if (!menuVisible) return;
    if (event.code === 'Escape' || event.code === 'Backspace') {
        closeMenu();
    }
});
