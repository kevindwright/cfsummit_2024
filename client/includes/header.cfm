<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title style="text-transform: uppercase"><cfoutput>#url.page.len() ? ucase(left(url.page, 1)) & right(url.page, url.page.len() - 1) : 'Dashboard'#</cfoutput></title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <!-- Bootstrap Icons CDN -->
  <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.10.5/font/bootstrap-icons.min.css" rel="stylesheet">
  <style>
    body {
      background-color: #f4f6f9;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      font-family: 'Roboto', sans-serif;
    }
    
    .root-container {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      width: 100%;
    }

    .login-container {
      width: 100%;
      max-width: 350px;
      padding: 20px;
      background-color: #fff;
      border-radius: 10px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      z-index: 1;
    }

    .login-header h3 {
      font-size: 20px;
      font-weight: 500;
      text-align: center;
      color: #333;
      margin-bottom: 25px;
    }

    .input-group {
      margin-bottom: 15px;
    }

    .input-group-text {
      background-color: #f4f6f9;
      border: none;
      color: #999;
    }

    .form-control {
      border: 1px solid #ddd;
      border-radius: 8px;
      height: 45px;
      font-size: 14px;
      color: #333;
    }

    .btn-primary {
      background-color: #007bff;
      border: none;
      width: 100%;
      padding: 10px;
      font-size: 16px;
      border-radius: 8px;
      margin-top: 15px;
      transition: background-color 0.3s;
    }

    .btn-primary:hover {
      background-color: #0056b3;
    }

    .form-footer {
      text-align: center;
      margin-top: 15px;
    }

    .form-footer a {
      color: #007bff;
      font-size: 14px;
      text-decoration: none;
    }

    .form-footer a:hover {
      text-decoration: underline;
    }

    .loader-overlay {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      background: rgba(0, 0, 0, 0.5);
      z-index: 10; 
      justify-content: center;
      align-items: center;
    }

    .loader {
      width: 50px;
      height: 50px;
      border: 6px solid #f3f3f3;
      border-radius: 50%;
      border-top: 6px solid #007bff;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>