package xin.installer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.logging.Logger;

import com.izforge.izpack.api.data.InstallData;
import com.izforge.izpack.api.data.PanelActionConfiguration;
import com.izforge.izpack.api.handler.AbstractUIHandler;
import com.izforge.izpack.data.PanelAction;
import com.izforge.izpack.util.Platform;


public class ShutdownNodeAction implements PanelAction {

	private static final Logger logger = Logger.getLogger(ShutdownNodeAction.class.getName());


	
	public ShutdownNodeAction() {
	}

	@Override
	public void initialize(PanelActionConfiguration configuration) {
	}

	@Override
	public void executeAction(InstallData installData, AbstractUIHandler handler) {
		logger.info("Executing ShutdownNodeAction: "+installData.getPlatform());
		shutdownServer(installData);
	}	


	public boolean shutdownServer(InstallData installData) {
		
		String installPath = installData.getDefaultInstallPath();
		String[] cmd = new String[2];
		
		if(installData.getPlatform().getName().isA(Platform.Name.UNIX) || Platform.Name.MAC.equals(installData.getPlatform().getName())) {
			cmd[0]="sh";
			cmd[1]=installPath +"/bin/stop.sh";
		} else if(Platform.Name.WINDOWS.equals(installData.getPlatform().getName())) {
			cmd[0]="cmd.exe";
			cmd[1]="/c "+installPath+"/bin/stop.bat";			
		}

		try {
			logger.info("Trying to shutdown server using shell");
			Process process = Runtime.getRuntime().exec(cmd);
			process.waitFor();
			handleShellResponse(process);
		} catch (Exception e) {
			logger.info("Could not shutdown server by calling " + Arrays.toString(cmd));
		}
		return true;
	}

	public boolean handleShellResponse(Process proc) throws IOException, InterruptedException {
		Boolean responseSuccess = null;
		InputStreamReader inputStreamReader;
		if (proc.exitValue() > 0) {
			responseSuccess = false;
			inputStreamReader = new InputStreamReader(proc.getErrorStream());
		} else {
			responseSuccess = true;
			inputStreamReader = new InputStreamReader(proc.getInputStream());
		}

		BufferedReader reader = new BufferedReader(inputStreamReader);
		StringBuilder response = new StringBuilder();
		String line = "";
		while ((line = reader.readLine()) != null) {
			response.append(line);
		}
		reader.close();
		
		String responseString = response.toString();
		logger.info("Shell response with status " + proc.exitValue() + " was: " + responseString);

		if (!responseSuccess || responseString.contains("errorCode")) {
			return false;
		}
		return responseSuccess;
	}
}
