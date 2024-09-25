
component {
    this.name = "Simple Coldfusion Rest API"

    this.webrootDir = getDirectoryFromPath( getCurrentTemplatePath() );

    this.mappings["/api/controller"] = this.webrootDir & "controller";
    
    this.restsettings = { 
        cfclocation: this.webrootDir & "controller" // a comma-delimeted list in a string
    };

    public function onApplicationStart() {
        application.name = this.name;

        application.keyPair = getKeyPairfromkeystore({  
            "keystore": expandPath("/keys/keystore.sample.p12"),
            "keystorePassword": "changeit",
            "keypairPassword": "changeit",
            "keystoreAlias": "simpleCFRestAPI"
        });

        application.JWTSignConfig = {
            "algorithm": "RS256",
            "generateIssuedAt": true,
            "generateJti": true
        };

        application.JWEConfig = {
            "algorithm": "RSA-OAEP",
            "encryption": "A128CBC-HS256"
        };

        application.generatorUtils = new api.model.utils.generator();

        application.DB["users"] = [
            {
                id: 1,
                username: "admin",
                password: "123",
                role: "admin",
                fingerprint: []
            },
            {
                id: 3,
                username: "kevin",
                password: "CF123",
                role: "user",
                fingerprint: []
            }
        ];

        application.DB["revoked_fingerprints"] = [];

        // Initialize REST service
        restInitApplication(this.restsettings.cfclocation, "api");
    }

    public boolean function onRequest(string targetPage) {
        if(url.keyExists('init')){
            applicationStop();
        }
        
        cfinclude(template=arguments.targetPage);

        return true;
    }
}