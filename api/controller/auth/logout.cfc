component rest="true" restPath="/auth/logout" consumes="application/json" produces="application/json" extends="api.controller.base"{

    public logout function init() {
        super.init()
        return this;
    }

    remote struct function logout() httpMethod="GET" returnFormat="JSON" {
        this.init();
        
        try{
            local.auth = authenticateUser();

            local.username = local.auth.authUser.username;
            local.fingerprint = local.auth.passport.fingerprint;
            
            // Invalidate current fingerprint
            local.authService = new api.model.auth.authService();
            local.authService.revokeFingerprint(local.username, local.fingerprint);

            return responseMessage(true, "user successfully logged out");
        }
        catch (any e) {
            return responseMessage(false, e.message);
        }
    }
}