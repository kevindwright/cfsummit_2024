component {

    public struct function generateToken(required string username, required string fingerprint, numeric tokenExpiryTimeInMinutes=1, numeric tokenExpiryTimeInDays=1) {
        try{
            local.authTokenExpiryTime = dateAdd("n", arguments.tokenExpiryTimeInMinutes, now());
            local.refreshTokenExpiryTime = dateAdd("d", arguments.tokenExpiryTimeInDays, now());
            local.tokenExpiryTimeInSeconds = arguments.tokenExpiryTimeInMinutes * 60;

            // Get User
            variables.username = arguments.username;
            local.getUser = application.DB["users"].filter(function(user){
                return user.username == variables.username;
            });
            if(local.getUser.len() <= 0){
                throw("can not generate token for user");
            }
            local.user = local.getUser[1];

            // Created Signed JWS token
            local.jwsPayload = {
                "iss": application.name,
                "sub": arguments.username,
                "fingerprint": arguments.fingerprint,
                "aud": "simple-cf-rest-api.com",
                "exp": local.authTokenExpiryTime,
                "iat": now(),
                "tokenType": "auth",
                "role": local.user.role
            };
            local.jwsToken = createSignedJWT(local.jwsPayload, application.keyPair.getPrivate(), application.JWTSignConfig);

            // Create Signed (encrypted) JWE token
            local.jwePayload = {
                "jwsToken": local.jwsToken,
                "fingerprint": arguments.fingerprint,
                "exp": local.authTokenExpiryTime
            };
            local.jweToken = createEncryptedJWT(local.jwePayload, application.keyPair.getPublic(), application.JWEConfig);

            // Create Signed Refresh Token
            local.refreshTokenPayload = {
                "iss": application.name,
                "fingerprint": arguments.fingerprint,
                "tokenType": "refresh",
                "exp": local.refreshTokenExpiryTime
            };
            local.refreshToken = createSignedJWT(local.refreshTokenPayload, application.keyPair.getPrivate(), application.JWTSignConfig);

            return {
                "accessToken": local.jweToken,
                "expiresIn": local.tokenExpiryTimeInSeconds,
                "refreshToken": local.refreshToken,
                "tokenType": "Bearer"
            };
        }
        catch(any e)    {
            return {
                "message": "unable to generate token",
                "error": e.message
            };
        }
    }

    public struct function refreshToken(required string refreshToken) {
        try{
            local.refreshToken = validateToken(arguments.refreshToken);
            if(local.refreshToken.keyExists('error')) {
                return local.refreshToken;
            }
            
            // Check if token is a refresh token
            if(local.refreshToken.keyExists('tokenType') && local.refreshToken.tokenType != "refresh" || !local.refreshToken.keyExists('tokenType')){
                return {
                    "message": "invalid refresh token",
                    "error": "invalid refresh token"
                };
            }

            // Set fingerprint to variable scope
            variables.fingerprint = local.refreshToken.fingerprint;

            // Check if fingerprint is still associated with user
            local.validUser = application.DB["users"].filter(function(user) {
                return user.fingerprint.contains(variables.fingerprint);
            });
            if (local.validUser.len() <= 0) {
                return {
                    "message": "invalid credentials",
                    "error": "invalid user"
                };
            }
            if(!local.validUser[1].fingerprint.contains(local.refreshToken.fingerprint)){
                return {
                    "message": "invalid refesh token",
                    "error": "refresh token is not valid for user"
                };
            }

            // Generate new token
            local.refreshedToken = generateToken(local.validUser[1].username, local.refreshToken.fingerprint);

            return local.refreshedToken;
        }
        catch(any e){
            return {
                "message": "unable to refresh token",
                "error": e.message
            };
        }
    }

    public boolean function revokeFingerprint(required string username, required string fingerprint){
        variables.username = arguments.username;
        variables.fingerprint = arguments.fingerprint;
        application.DB["users"] = application.DB["users"].map(function(user){
            if(user.username == variables.username && user.fingerprint.contains(variables.fingerprint)) {
                arrayDeleteNoCase(user.fingerprint, variables.fingerprint);
                application.DB["revoked_fingerprints"].append(variables.fingerprint);
            }
            return user;
        })

        return true
    }

    public struct function validateToken(required string token, string type="jwt") {
        try {
            if(arguments.type == "jwe") {
                local.validatedToken = verifyEncryptedJWT(arguments.token, application.keyPair.getPrivate(), {returnType: "struct"});
            }
            else {
                local.validatedToken = verifySignedJWT(arguments.token, application.keyPair.getPublic(), {returnType: "struct"});
            }

            if(!local.validatedToken.valid){
                throw(
                    message = local.validatedToken.validation_failed_reason,
                    errorcode = "401-EXPIRED-JWE"
                );
            }

            if(local.validatedToken.keyExists("jwsToken")){
                local.validatedToken = validateToken(local.validatedToken.jwsToken);

                if(!local.validatedToken.valid){
                    throw(
                        message = local.validatedToken.validation_failed_reason,
                        errorcode = "401-EXPIRED-JWT"
                    );
                }
            }
            
            if(local.validatedToken.keyExists("fingerprint")) {
                variables.validatedUserFingerprint = local.validatedToken.fingerprint;
                local.userForToken = application.DB["users"].filter(function(user){
                    return user.fingerprint.contains(variables.validatedUserFingerprint);
                })

                if(local.userForToken.len() <= 0){
                    throw("invalid token");
                }
            }
            else {
                throw("fingerprint not found");
            }

            return local.validatedToken;
        }
        catch(any e) {
            return {
                "message": "an error occurred validating token",
                "error": e.message,
                "errorCode": e.errorCode
            }
        }
    }
}