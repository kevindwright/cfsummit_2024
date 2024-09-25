component rest="true" restPath="/auth/refresh-token" consumes="application/json" produces="application/json" extends="api.controller.base"{

    public refreshToken function init() {
        super.init()
        return this;
    }

    remote struct function refreshToken() httpMethod="POST" returnFormat="JSON" {
        this.init();
    
        try{
            local.requestHttpHeader = getHttpHeaders();
            local.requestHeaderCookie =  {
                success: false,
                data: {}
            };
            if(local.requestHttpHeader.keyExists('cookie')) {
                local.requestHeaderCookie.success = true;
                for(local.eachCookie in listToArray(local.requestHttpHeader.cookie, ";")){
                    local.cookieKeyValue = listToArray(eachCookie, "=");
                    if(local.cookieKeyValue.len() == 2) {
                        local.requestHeaderCookie.data[trim(local.cookieKeyValue[1])] = trim(local.cookieKeyValue[2]);
                    }
                }
            }

            if(!isValidRequest(local.requestHeaderCookie, ["refreshToken"], false)) {
                restSetResponse({
                    status: 401,
                    headers: {
                        explanation: "invalid request"
                    },
                    content: serializeJSON(responseMessage(false, "invalid request. could not find refreshToken in headers"))
                });

                return responseMessage(false, "invalid request. could not find refreshToken in headers");
            }

            local.refreshToken = local.requestHeaderCookie.data["refreshToken"];

            // Refresh token
            local.authService = new api.model.auth.authService();
            local.refresh = local.authService.refreshToken(local.refreshToken);

            if(local.refresh.keyExists('error')) {
                return responseMessage(false, local.refresh.message, local.refresh);
            }

            // Set cookie with HttpOnly, Secure, and SameSite attributes
            local.cookie = {
                name: "refreshToken",
                value: local.refresh.refreshToken,
                expiration: dateAdd("d", 30, now()),
                path: "/"
            };
            local.cookieHeader = local.cookie.name & "=" & local.cookie.value & "; Expires=" & getHttpTimeString(local.cookie.expiration) & "; Path=" & local.cookie.path & "; HttpOnly; SameSite=Lax; Secure";

            restSetResponse({
                status: 200,
                headers: {
                    "Set-Cookie": local.cookieHeader
                },
                content: serializeJSON(responseMessage(true, "token was successfully refreshed", local.refresh))
            });

            return responseMessage(true, "token was successfully refreshed", local.refresh);
        }
        catch(any e) {
            return responseMessage(false, e.message);
        }
    }
}