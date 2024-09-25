abstract component accessors="true" {

    property name="httpBody" type="struct";
    property name="httpMethod" type="string";
    property name="httpHeaders" type="struct";
    property name="httpProtocol" type="string";

    public base function init() {
        local.requestData = getHttpRequestData();

        variables.httpBody = parseBody(local.requestData.content);
        variables.httpMethod = local.requestData.method;
        variables.httpHeaders = local.requestData.headers;
        variables.httpProtocol = local.requestData.protocol;
        
        return this;
    }

    private struct function authenticateUser() {
        local.requestHttpHeader = getHttpHeaders();
        if(!local.requestHttpHeader.keyExists("Authorization")) {
            restSetResponse({
                status: 401,
                headers: {
                    explanation: "Authorization header missing"
                },
                content: ""
            });
            throw("Authorization header missing");
        }
        local.authorizationHeader = local.requestHttpHeader["Authorization"];

        if (left(local.authorizationHeader, 7) != "Bearer ") {
            restSetResponse({
                status: 401,
                headers: {
                    explanation: "Invalid Authorization header. Bearer token required"
                }
            });
            throw("Invalid Authorization header. Bearer token required.");
        }
        local.bearerToken = trim(mid(local.authorizationHeader, 8, len(local.authorizationHeader)-7));

        if (isNull(local.bearerToken) or local.bearerToken.len() == 0) {
            restSetResponse({
                status: 401,
                headers: {
                    explanation: "Bearer token is missing"
                }
            });
            throw("Bearer token is missing.");
        }

        // Validate Bearer token
        local.authService = new api.model.auth.authService();
        local.authenticate = local.authService.validateToken(local.bearerToken, "jwe");

        if(local.authenticate.keyExists('error')) {
            restSetResponse({
                status: 401,
                headers: {
                    explanation: local.authenticate.error,
                    errorcode: local.authenticate.keyExists('errorCode') ? local.authenticate.errorCode : 401
                }
            });
            throw(local.authenticate.error);
        }

        // Check if token is an auth token
        if(local.authenticate.keyExists('tokenType') && local.authenticate.tokenType != "auth" || !local.authenticate.keyExists('tokenType')){
            restSetResponse({
                status: 401,
                headers: {
                    explanation: "Invalid auth token"
                }
            });
            throw("Invalid auth token");
        }

        // Check these keys exists in the token
        if(local.authenticate.keyExists("sub") && local.authenticate.keyExists("fingerprint")) {
            variables.authenticatedFingerprint = local.authenticate.fingerprint;
            variables.authenticatedUsername = local.authenticate.sub;
            
            local.getUser = application.DB["users"].filter(function(user){
                return user.username == variables.authenticatedUsername && user.fingerprint.contains(variables.authenticatedFingerprint);
            });

            if(local.getUser.len() > 0){
                return {
                    authUser: local.getUser[1],
                    passport: local.authenticate
                };
            }

            restSetResponse({
                status: 401,
                headers: {
                    explanation: "no user found"
                }
            });
            throw("no user found");
        }

        restSetResponse({
            status: 401,
            headers: {
                explanation: "invalid authorization value"
            }
        });
        throw("invalid authorization value");
    }

    private boolean function isValidRequest(required struct request, array mustContainKeys=[], boolean strict=true) {
        if(arguments.request.keyExists('success') && !arguments.request.success) {
            return false;
        }

        // If strict mode is enabled, ensure that the number of keys in the 'request.data' struct
        // matches the number of required keys specified in the 'mustContainKeys' array.
        if(arguments.strict && arguments.request.data.count() != arguments.mustContainKeys.len()){
            return false;
        }

        // If 'mustContainKeys' is not empty, ensure all keys exists in the request.data
        local.containKeys = true; 
        for(key in arguments.mustContainKeys) {
            if(!arguments.request.data.keyExists(key)){
                local.containKeys = false;
                return false;
                break;
            }
        }

        return true;
    }

    private struct function responseMessage(required boolean success, string message="", any detail={}){
        return {
            "status": arguments.success ? "success" : "failure",
            "message": arguments.message,
            "detail": arguments.detail
        };
    }

    private struct function parseBody(required string content) {
        try{
            local.content = deserializeJSON(arguments.content);

            if(isValid("struct", local.content)){
                return {
                    "success": true,
                    "data": local.content
                };
            }

            throw("Not a valid body");
        }
        catch (any e) {
            return {
                "success": false,
                "error": e.message
            };
        }
    }
}