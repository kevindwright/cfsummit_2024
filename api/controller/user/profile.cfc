component rest="true" restPath="/user" consumes="application/json" produces="application/json" extends="api.controller.base"{

    public profile function init() {
        super.init()
        return this;
    }

    remote struct function userProfile() httpMethod="GET" restPath="profile" returnFormat="JSON" {
        this.init();
        
        try{
            local.auth = authenticateUser();

            // Get User
            variables.authUser = local.auth.authUser;
            local.getUser = application.DB["users"].filter(function(user){
                return user.id == variables.authUser.id;
            });

            if(local.getUser.len() <= 0){
                restSetResponse({
                    status: 404,
                    content: responseMessage(false, "no profile found for user")
                })

                throw("no profile found for user");
            }

            // remove password from struct
            local.result = local.getUser[1].filter(function(key, value){
                return key != "password";
            });
            
            return responseMessage(true, "", local.result);
        }
        catch (any e) {
            return responseMessage(false, e.message);
        }
    }
}