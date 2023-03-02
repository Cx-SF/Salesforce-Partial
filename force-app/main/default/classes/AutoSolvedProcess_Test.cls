@IsTest
public class AutoSolvedProcess_Test  {
	@IsTest
	public static void autoSolveTest1(){
		case c = new case();
		insert c;

		Map<String, Object> obj = AutoSolvedProcess.startProcess(c.id);
		System.debug('obj: ' + obj);
		Id batchProcessId = (Id) obj.get('batchId');
		AutoSolvedProcess.getBatchInfo(batchProcessId);
	}
}