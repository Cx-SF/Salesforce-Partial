global class MonitorRecursionClass {
	private static Boolean FullRegistrationFlowMonitor = false;
    
    public static Boolean getFullRegistrationFlowMonitor() {
        return FullRegistrationFlowMonitor;
    }

    public static void setFullRegistrationFlowMonitor(Boolean value) {
        FullRegistrationFlowMonitor = value;
    }
}