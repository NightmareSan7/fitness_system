const statsPanel = document.getElementById('statsPanel');
const statsList = document.getElementById('statsList');
const closeButton = document.getElementById('closeButton');
const trainingBox = document.getElementById('trainingBox');
const trainingLabel = document.getElementById('trainingLabel');
const trainingProgress = document.getElementById('trainingProgress');
const xpPopup = document.getElementById('xpPopup');
const xpPopupProgressFill = document.getElementById('xpPopupProgressFill');
const xpTitle = document.getElementById('xpTitle');
const xpDetails = document.getElementById('xpDetails');

let currentStats = {};
let xpPopupTimeout = null;
let trainingTimeout = null;

function showEl(element) {
	element.classList.remove('hidden');
}

function hideEl(element) {
	element.classList.add('hidden');
}

function getProgressPercent(currentXp, maxXp) {
	if (!maxXp || maxXp <= 0) {
		return 100;
	}

	return Math.max(0, Math.min(100, (currentXp / maxXp) * 100));
}

function renderStats(stats) {
	currentStats = stats || {};
	statsList.innerHTML = '';

	Object.entries(currentStats).forEach(([stat, data]) => {
		const label = data.label || stat;
		const level = Number(data.level) || 1;
		const maxLevel = Number(data.maxLevel) || level;
		const xp = Number(data.xp) || 0;
		const requiredXp = Number(data.requiredXp) || 0;
		const isMaxLevel = data.isMaxLevel === true;
		const percent = isMaxLevel ? 100 : getProgressPercent(xp, requiredXp);

		const card = document.createElement('div');
		card.className = 'stat-card';

		const statTop = document.createElement('div');
		statTop.className = 'stat-top';

		const statNameEl = document.createElement('span');
		statNameEl.className = 'stat-name';
		statNameEl.textContent = label;

		const statLevelEl = document.createElement('span');
		statLevelEl.className = 'stat-level';
		statLevelEl.textContent = `Level ${level}${isMaxLevel ? ' / Max' : ` / ${maxLevel}`}`;

		statTop.appendChild(statNameEl);
		statTop.appendChild(statLevelEl);

		const progressBg = document.createElement('div');
		progressBg.className = 'progress-bg';

		const progressFill = document.createElement('div');
		progressFill.className = 'progress-fill stat-progress-fill';
		progressFill.dataset.percent = percent;
		progressFill.style.width = '0%';

		progressBg.appendChild(progressFill);

		const statXpEl = document.createElement('div');
		statXpEl.className = 'stat-xp';
		statXpEl.textContent = isMaxLevel ? 'Max Level' : `${xp} / ${requiredXp} XP`;

		card.appendChild(statTop);
		card.appendChild(progressBg);
		card.appendChild(statXpEl);

		statsList.appendChild(card);
	});
	requestAnimationFrame(() => {
		requestAnimationFrame(() => {
			document.querySelectorAll('.stat-progress-fill').forEach((bar) => {
				bar.style.width = `${bar.dataset.percent}%`;
			});
		});
	});
}

function startTraining(label, duration) {
	clearTimeout(trainingTimeout);

	const total = Number(duration) || 5000;

	trainingLabel.textContent = label || 'Training...';

	trainingProgress.style.transition = 'none';
	trainingProgress.style.width = '0%';

	showEl(trainingBox);

	requestAnimationFrame(() => {
		requestAnimationFrame(() => {
			trainingProgress.style.transition = `width ${total}ms linear`;
			trainingProgress.style.width = '100%';
		});
	});

	trainingTimeout = setTimeout(() => {
		hideEl(trainingBox);
		trainingProgress.style.transition = 'none';
		trainingProgress.style.width = '0%';
		trainingTimeout = null;
	}, total);
}
function showXpPopup(data) {
	clearTimeout(xpPopupTimeout);

	const label = data.label || data.stat || '';
	const gainedXp = Number(data.xp) || 0;
	const level = Number(data.level) || 1;
	const currentXp = Number(data.currentXp) || 0;
	const requiredXp = Number(data.requiredXp) || 0;
	const leveledUp = data.leveledUp === true;
	const isMaxLevel = data.isMaxLevel === true || requiredXp <= 0;

	const startPercent = (isMaxLevel || leveledUp) ? 0 : getProgressPercent(Math.max(0, currentXp - gainedXp), requiredXp);
	const endPercent = isMaxLevel ? 100 : getProgressPercent(currentXp, requiredXp);

	xpTitle.textContent = `+${gainedXp} XP ${label}`;
	xpDetails.textContent = leveledUp ? `Level Up! Neues Level: ${level}` : `Level ${level}`;

	xpPopupProgressFill.style.transition = 'none';
	xpPopupProgressFill.style.width = `${startPercent}%`;

	showEl(xpPopup);

	requestAnimationFrame(() => {
		requestAnimationFrame(() => {
			xpPopupProgressFill.style.transition = 'width 700ms ease-out';
			xpPopupProgressFill.style.width = `${endPercent}%`;
		});
	});

	xpPopupTimeout = setTimeout(() => {
		hideEl(xpPopup);
	}, 3500);
}

function closeStats() {
	hideEl(statsPanel);

	fetch(`https://${GetParentResourceName()}/close`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json; charset=UTF-8'
		},
		body: JSON.stringify({})
	});
}

closeButton.addEventListener('click', closeStats);

document.addEventListener('keydown', (event) => {
	if (event.key === 'Escape') {
		closeStats();
	}
});

window.addEventListener('message', (event) => {
	const data = event.data || {};
	switch (data.type) {
		case 'updateStats':
			renderStats(data.stats);
			break;

		case 'openStats':
			renderStats(data.stats || currentStats);
			showEl(statsPanel);
			break;

		case 'closeStats':
			hideEl(statsPanel);
			break;

		case 'trainingStart':
			startTraining(data.label, data.duration);
			break;

		case 'xpPopup':
			showXpPopup(data);
			break;
	}
});
