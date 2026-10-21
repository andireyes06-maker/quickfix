// Local emulator accounts only. No production Firebase requests.
(async () => {
  for (const user of [
    { email: 'maria.santos.act5@example.com', password: 'quickfix-local-only', name: 'Maria Santos' },
    { email: 'juan.delacruz.act5@example.com', password: 'quickfix-local-only', name: 'Juan Dela Cruz' },
  ]) {
    const response = await fetch('http://127.0.0.1:9199/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: user.email, password: user.password, displayName: user.name, returnSecureToken: true }),
    });
    const result = await response.json();
    if (!response.ok && result.error.message !== 'EMAIL_EXISTS') { throw Error(result.error.message); }
    console.log(response.ok ? 'Created local demo account: ' + user.name : 'Local demo account already exists: ' + user.name);
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
