<!DOCTYPE html>
<html lang="en">
<cfscript>
    param name="url.page" default="";

    include "includes/header.cfm";

    switch (url.page) {
        default:
        case "dashboard":
            include "dashboard/info.cfm";
            break;
        case "login":
            include "auth/login.cfm";
            break;            
    }

    include "includes/footer.cfm";
</cfscript>
<script>
    <cfoutput>
        let #toScript(url.page, "currentPage")#;
    </cfoutput>

    function isLoggedIn() {
        return sessionStorage.getItem('accessToken') !== null;
    }

    function redirectIfLoggedIn() {
        if (isLoggedIn() && ["login"].includes(currentPage)) {
            window.location.href = '?page=dashboard';
        }
        else if(!isLoggedIn() && !["login"].includes(currentPage)) {
            window.location.href = '?page=login';
        }
    }

    function setAccessToken(accessToken, expiresIn) {
        sessionStorage.setItem('accessToken', accessToken);
        const expiresInMs = expiresIn * 1000;
        const expirationDate = new Date(Date.now() + expiresInMs);
        sessionStorage.setItem('accessTokenExpiry', expirationDate.toISOString());
    }

    function removeAccessToken() {
        sessionStorage.removeItem('accessToken');
        sessionStorage.removeItem('accessTokenExpiry');
    }

    window.addEventListener('load', redirectIfLoggedIn);
</script>

</html>