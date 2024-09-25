<body>
  <main class="root-container">
    <div class="login-container">
      <div class="login-header">
        <h3>Sign In</h3>
      </div>

      <form id="loginForm">
        <div class="input-group">
          <span class="input-group-text"><i class="bi bi-envelope-fill"></i></span>
          <input value="kevin" type="username" autocomplete="off" class="form-control" id="username" placeholder="Enter username" required>
        </div>

        <div class="input-group">
          <span class="input-group-text"><i class="bi bi-lock-fill"></i></span>
          <input value="CF123" type="password" class="form-control" id="password" placeholder="Enter password" required>
        </div>

        <button type="submit" class="btn btn-primary">Sign In</button>
      </form>
    </div>

    <!-- Full-page overlay loader -->
    <div class="loader-overlay" id="loaderOverlay">
      <div class="loader"></div>
    </div>
  </main>
  
  <script>
    document.getElementById('loginForm').addEventListener('submit', function(event) {
      event.preventDefault();
  
      const username = document.getElementById('username').value;
      const password = document.getElementById('password').value;
      const loaderOverlay = document.getElementById('loaderOverlay');
  
      // Show loader overlay
      loaderOverlay.style.display = 'flex';
  
      fetch('/rest/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
      })
      .then(response => response.json())
      .then(data => {
        loaderOverlay.style.display = 'none';
        if (data.detail.accessToken && data.detail.expiresIn) {
            setAccessToken(data.detail.accessToken, data.detail.expiresIn);
            window.location.reload();
        } else {
            alert('Invalid credentials. Please try again.');
        }
      })
      .catch(error => {
        loaderOverlay.style.display = 'none';
        alert('An error occurred. Please try again.');
        console.error('Error:', error);
      });
    });
  </script>
</body>