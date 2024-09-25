<style>
  .profile-container {
    width: 450px;
    background-color: #ffffff;
    border-radius: 12px;
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
    padding: 30px;
  }
  
  .profile-header {
    text-align: center;
    margin-bottom: 25px;
  }

  .profile-header h2 {
    font-size: 26px;
    font-weight: bold;
    color: #333;
  }

  .profile-header h4 {
    font-size: 18px;
    color: #555;
    margin-top: 5px;
  }

  .profile-details {
    margin-bottom: 25px;
  }

  .profile-details p {
    font-size: 16px;
    color: #444;
    margin-bottom: 10px;
    line-height: 1.5;
  }

  .profile-details span {
    font-weight: bold;
    color: #222;
  }

  /* Fingerprint Section */
  .fingerprint-section {
    margin-top: 20px;
  }

  .fingerprint-section h3 {
    font-size: 20px;
    font-weight: bold;
    color: #333;
    margin-bottom: 10px;
  }

  .fingerprint-list {
    list-style: none;
    padding-left: 0;
    margin: 0;
  }

  .fingerprint-list li {
    background-color: #f4f4f4;
    margin-bottom: 8px;
    padding: 10px;
    border-radius: 8px;
    color: #333;
    font-size: 14px;
    display: flex;
    align-items: center;
  }

  .fingerprint-list li span {
    font-weight: bold;
    margin-right: 8px;
  }

  .logout-button {
    margin-top: 20px;
    padding: 12px;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.3s;
    width: 100%;
  }

  .logout-button:hover {
    background-color: #0056b3;
  }

  .text-capitalized {
    text-transform: capitalize;
  }
  
</style>

<body>
  <main class="root-container">
    <div class="profile-container">
      <div class="profile-header">
        <h2>Welcome, <span style="text-transform: uppercase" class="username"></span></h2>
        <h4>User Profile</h4>
      </div>
    
      <div class="profile-details">
        <p>User ID: <span class="text-capitalized" id="userId"></span></p>
        <p>Username: <span class="username text-capitalized"></span></p>
        <p>Role: <span class="text-capitalized" id="role"></span></p>
      </div>
    
      <div class="fingerprint-section">
        <h3>Fingerprints</h3>
        <ul class="fingerprint-list" id="fingerprintList"></ul>
      </div>

      <hr>

      <div id="countdownContainer" style="display: none;">
        <p style="color: red; border: 2px solid red; border-radius: 10px; padding: 10px; text-align: center;">
          <span id="countdown">00:00</span>
        </p>
      </div>
    
      <button class="logout-button" id="logoutBtn">Log Out</button>
    </div>
  </main>
    
  <script>
    let countdownInterval;
  
    function startTokenCountdown() {
      const expirationDate = sessionStorage.getItem('accessTokenExpiry');
      if (expirationDate) {
        const expirationTime = new Date(expirationDate).getTime();
  
        countdownInterval = setInterval(() => {
          const currentTime = Date.now();
          const timeRemaining = expirationTime - currentTime;
  
          if (timeRemaining <= 0) {
            document.getElementById('countdown').textContent = 'Access Token expired';
            clearInterval(countdownInterval);
          } else {
            const minutes = Math.floor(timeRemaining / (1000 * 60));
            const seconds = Math.floor((timeRemaining % (1000 * 60)) / 1000);
  
            const formattedSeconds = seconds < 10 ? '0' + seconds : seconds;
  
            document.getElementById('countdown').textContent = `${minutes}:${formattedSeconds}`;
          }
        }, 100);

        document.getElementById('countdownContainer').style.display = 'block';
      }
    }
  
    function fetchUserProfile() {
      const accessToken = sessionStorage.getItem('accessToken');
  
      if (accessToken) {
        fetch('/rest/api/user/profile', {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`
          }
        })
        .then(response => {
          if (response.status === 401) {
            const errorcode = response.headers.get('Errorcode');
            
            if (errorcode === '401-EXPIRED-JWE') {
              console.log('Access Token expired, trying to refresh token...');
              return refreshToken().then(() => fetchUserProfile()); // Fetch user profile again after token refresh
            } else {
              // If it's a 401 error but not expired, clear accessToken in the session and reload the page
              removeAccessToken();
              window.location.reload();
            }
          } else {
            return response.json();
          }
        })
        .then(data => {
          if (data && data.status === 'success') {
            const userDetails = data.detail;
            const userId = userDetails.ID;
            const username = userDetails.USERNAME;
            const role = userDetails.ROLE;
            const fingerprints = userDetails.FINGERPRINT;
      
            document.getElementById('userId').textContent = userId;
            document.querySelectorAll('.username').forEach(function(element) {
              element.textContent = username;
            });
            document.getElementById('role').textContent = role;
      
            // Populate the fingerprints list
            const fingerprintList = document.getElementById('fingerprintList');
            fingerprintList.innerHTML = '';
            fingerprints.forEach((fingerprint, index) => {
              const listItem = document.createElement('li');
              listItem.innerHTML = `<span>#${index + 1}</span> ${fingerprint}`;
              fingerprintList.appendChild(listItem);
            });
  
            startTokenCountdown();
          } else {
            console.log('Failed to load user profile...');
          }
        })
        .catch(error => {
          console.error('Error fetching profile:', error);
          console.log('An error occurred while fetching the user profile.');
        });
      } else {
        window.location.reload();
      }
    }
  
    function refreshToken() {
      return fetch('/rest/api/auth/refresh-token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include' // Include cookies containing the http-only refreshToken
      })
      .then(response => response.json())
      .then(data => {
        if (data.status === 'success') {
          setAccessToken(data.detail.accessToken, data.detail.expiresIn);
  
          console.log('Token refreshed successfully.');

          // Stop current countdown and start a new one
          clearInterval(countdownInterval);
          startTokenCountdown();
        } else {
          throw new Error("Failed to refresh token. Please log in again.");
        }
      })
      .catch(error => {
        console.error('Error refreshing token:', error);
        alert('Failed to refresh token. Please log in again.');

        removeAccessToken();
        window.location.reload();
      });
    }
  
    window.addEventListener('load', fetchUserProfile);
  
    // Event handler for Logout
    document.getElementById('logoutBtn').addEventListener('click', function () {
      fetch('/rest/api/auth/logout', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${sessionStorage.getItem('accessToken')}`,
          'Content-Type': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.status === 'success') {
          console.log('Logout successful');
          removeAccessToken();
          window.location.reload();
        } else {
          alert('Failed to log out. Please try again.');
        }
      })
      .catch(error => {
        console.error('Error logging out:', error);
        alert('An error occurred while logging out. Please try again.');
      });
    });
  </script>
</body>