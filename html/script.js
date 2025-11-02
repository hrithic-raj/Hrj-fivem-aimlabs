window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    document.getElementById('menu').classList.remove('hidden');

    const diffSelect = document.getElementById('difficulty');
    const wepSelect = document.getElementById('weapon');

    diffSelect.innerHTML = '';
    wepSelect.innerHTML = '';

    data.difficulties.forEach(d => {
      const opt = document.createElement('option');
      opt.text = d;
      opt.value = d;
      diffSelect.add(opt);
    });

    data.weapons.forEach(w => {
      const opt = document.createElement('option');
      opt.text = w;
      opt.value = w;
      wepSelect.add(opt);
    });
  }

  if (data.action === 'close') {
    document.getElementById('menu').classList.add('hidden');
  }
});

document.getElementById('start').addEventListener('click', () => {
  const difficulty = document.getElementById('difficulty').value;
  const weapon = document.getElementById('weapon').value;

  fetch(`https://${GetParentResourceName()}/startMatch`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({ difficulty, weapon })
  });
});

document.getElementById('close').addEventListener('click', () => {
  fetch(`https://${GetParentResourceName()}/closeMenu`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({})
  });
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    });
  }
});
