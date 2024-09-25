
# CF REST API w/ JWTs (Adobe ColdFusion 2023)

This project is a simple REST API built with Adobe ColdFusion (2023) implementing JWT/JWE authentication.
It utilizes new methods in ColdFusion 2023 for interacting with JSON Web Tokens;

   - createSignedJWT
   - createEncryptedJWT
   - verifySignedJWT
   - verifyEncryptedJWT


## Features
- JWT authentication for secure API access
- Token refresh and validation logic
- Protected Endpoints
- Simple UI for testing API

## Requirements
- Adobe ColdFusion 2023 (ACF)
- Java JDK 11+

## Running the Project
Access the application at http://localhost:8500
> `8500` is Coldfusion's default PORT. Replace PORT or SERVERNAME, if different.


## API Endpoints

### Authentication
- **POST** `rest/api/auth/login`  
  Logs in a user and returns JWE and refresh tokens.

### Token Refresh
- **POST** `rest/api/auth/refresh-token`  
  Refreshes expired tokens.

### User Profile (Protected Resource)
- **GET** `/rest/api/user/profile`  
  Requires valid JWT to access a protected resource.

### Logout
- **POST** `rest/api/auth/logout`  
  Revokes Fingerprint and invalidate associated access and refresh tokens.

## Testing the API 
A simple UI is included for testing the API. 
### User Dashboard
Navigate to `/client` and interact with the API endpoints using the interface.
### Viewing APIs Current/Revoked Fingerprints (Tokens) 
Navigate to `/api` to view.

## Generating Signing Keys
```bash
    openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
    openssl rsa -pubout -in private_key.pem -out public_key.pem
    openssl req -new -x509 -key private_key.pem -out certificate.crt -days 365
    openssl pkcs12 -export -in certificate.crt -inkey private_key.pem -out keystore.p12 -name simpleCFRestAPI -passout pass:changeit
```
