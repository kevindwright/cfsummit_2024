component rest="true" restPath="/auth/login" consumes="application/json" produces="application/json" extends="api.controller.base" {

    public login function init() {
        super.init()
        return this;
    }

    remote struct function login() httpMethod="POST" returnFormat="JSON" {
        this.init();

        try{
            local.requestHttpBody = getHttpBody();
            if(!isValidRequest(local.requestHttpBody, ["username", "password"]) ) {
                return responseMessage(false, "invalid payload. please pass only username and password");
            }

            variables.username = local.requestHttpBody.data["username"];
            variables.password = local.requestHttpBody.data["password"];

            // Validate user login details
            local.validUser = application.DB["users"].filter(function(user) {
                return user.username == variables.username && user.password == variables.password;
            });
            if (local.validUser.len() <= 0) {
                return responseMessage(false, "invalid credentials");
            }

            local.authService = new api.model.auth.authService();
            variables.fingerprint = application.generatorUtils.generateGUID();

            local.token = local.authService.generateToken(variables.username, variables.fingerprint);
            if(local.token.keyExists('error')) {
                return responseMessage(false, local.token.message, local.token);
            }
            
            // Update the user with the valid fingerprint
            application.DB["users"] = application.DB["users"].map(function(user){
                if(user.username == variables.username && user.password == variables.password) {
                    user.fingerprint.append(variables.fingerprint);
                }
                return user
            })

            // Set cookie with HttpOnly, Secure, and SameSite attributes
            local.cookie = {
                name: "refreshToken",
                value: local.token.refreshToken,
                expiration: dateAdd("d", 1, now()),
                path: "/"
            };
            local.cookieHeader = local.cookie.name & "=" & local.cookie.value & "; Expires=" & getHttpTimeString(local.cookie.expiration) & "; Path=" & local.cookie.path & "; HttpOnly; SameSite=Lax; Secure";

            restSetResponse({
                status: 200,
                headers: {
                    "Set-Cookie": local.cookieHeader
                },
                content: serializeJSON(responseMessage(true, "you have successfully logged in", local.token))
            });

            return responseMessage(true, "you have successfully logged in", local.token)
        }
        catch(any e){
            return responseMessage(false, e.message);
        }
    }

}