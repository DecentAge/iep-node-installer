package xin.installer;

import java.util.logging.Logger;

import com.izforge.izpack.api.data.InstallData;
import com.izforge.izpack.api.data.PanelActionConfiguration;
import com.izforge.izpack.api.handler.AbstractUIHandler;
import com.izforge.izpack.data.PanelAction;

public class UpdateNodePropertiesAction implements PanelAction {

	private static final Logger logger = Logger.getLogger(UpdateNodePropertiesAction.class.getName());

	public UpdateNodePropertiesAction() {
	}

	@Override
	public void initialize(PanelActionConfiguration configuration) {
		logger.info("Executing initialize");
	}

	@Override
	public void executeAction(InstallData installData, AbstractUIHandler handler) {
		String targetEnv = installData.getVariable("iep.installer.targetEnv");
		logger.info("Executing executeAction with targetEnv "+targetEnv);
		setVariable("xin.defaultPeers", targetEnv, installData);
		setVariable("xin.apiServerPort", targetEnv, installData);
		setVariable("xin.peerServerPort", targetEnv, installData);
		setVariable("xin.defaultPeerPort", targetEnv, installData);		
	}
	
	public void setVariable(String name, String targetEnv, InstallData installData) {
		String value = installData.getVariable("iep.installer."+targetEnv+"."+name);
		installData.setVariable("iep.installer."+name, value);
	}
}
