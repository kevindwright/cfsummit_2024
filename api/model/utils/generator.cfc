
component {
    public string function generateGUID() {
        return insert("-", CreateUUID(), 23);
    }
}