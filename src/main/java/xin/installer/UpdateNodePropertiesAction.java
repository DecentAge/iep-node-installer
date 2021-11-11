package xin.installer;

import java.util.logging.Logger;

import com.izforge.izpack.api.data.InstallData;
import com.izforge.izpack.api.data.PanelActionConfiguration;
import com.izforge.izpack.api.handler.AbstractUIHandler;
import com.izforge.izpack.data.PanelAction;

public class UpdateNodePropertiesAction implements PanelAction {

	private static final Logger logger = Logger.getLogger(UpdateNodePropertiesAction.class.getName());
	public static final String FILE_PATH = "conf/nxt-installer.properties";

	public UpdateNodePropertiesAction() {
	}

	@Override
	public void initialize(PanelActionConfiguration configuration) {
		logger.info("Executing initialize");
	}

	@Override
	public void executeAction(InstallData installData, AbstractUIHandler handler) {

		String targetEnv = installData.getVariable("iep.installer.targetEnv");

		if ("testnet".equals(targetEnv)) {
			installData.setVariable("iep.installer.apiServerPort", "9876");
			installData.setVariable("iep.installer.peerPort", "8776");
		} else if ("mainnet".equals(targetEnv)) {
			installData.setVariable("iep.installer.apiServerPort", "23457");
			installData.setVariable("iep.installer.peerPort", "23456");
		}
		logger.info("Executing executeAction with targetEnv "+targetEnv);
	}
}
