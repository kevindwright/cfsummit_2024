component rest="true" restPath="/" produces="application/json" {
    
    remote struct function index() httpMethod="GET" returnFormat="JSON" {
        return {
            "success": true,
            "message": "API Service is running..."
        }
    }
}