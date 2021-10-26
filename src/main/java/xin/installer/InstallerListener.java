/*
 * Copyright © 2013-2016 The Nxt Core Developers.
 * Copyright © 2016-2020 Jelurida IP B.V.
 *
 * See the LICENSE.txt file at the top-level directory of this distribution
 * for licensing information.
 *
 * Unless otherwise agreed in a custom licensing agreement with Jelurida B.V.,
 * no part of the Nxt software, including this file, may be copied, modified,
 * propagated, or distributed except according to the terms contained in the
 * LICENSE.txt file.
 *
 * Removal or modification of this copyright notice is prohibited.
 *
 */

package xin.installer;



import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.izforge.izpack.api.data.InstallData;
import com.izforge.izpack.api.data.Pack;
import com.izforge.izpack.api.event.ProgressListener;
import com.izforge.izpack.api.event.ProgressNotifiers;
import com.izforge.izpack.event.AbstractProgressInstallerListener;

public class InstallerListener extends AbstractProgressInstallerListener {

	private static final Logger logger = Logger.getLogger(InstallerListener.class.getName());

	private final ConfigHandler handler = new ConfigHandler();

	public InstallerListener(InstallData installData) {
		super(installData);
	}

	public InstallerListener(InstallData installData, ProgressNotifiers notifiers) {
		super(installData, notifiers);
	}

	@Override
	public void beforePacks(List<Pack> packs) {
		logger.info("Trying to shutdown the server");
		boolean shutdownServer = getVariable(ConfigHandler.VAR_SHUTDOWN_SERVER);
		if (shutdownServer) {
			if (handler.shutdownServer()) {
				logger.info("Sucessfully shutdown server");
			} else
				logger.log(Level.SEVERE, "Failed to stop server");
		}

		if (getVariable(ConfigHandler.VAR_CLEAN_INSTALL_DIR)) {
			if (!handler.cleanXinInstallDir(getInstallData().getInstallPath(), shutdownServer)) {
				logger.log(Level.SEVERE, "Failed to remove existing installation");
			} else
				logger.info("Not removing existing installation " +getInstallData().getInstallPath());
		}
	}

	@Override
	public void afterPacks(List<Pack> packs, ProgressListener listener) {
		logger.info("Completing package installation");
		getInstallData().setVariable("xin.installer.packInstallCompleted", "true");
	}

	@Override
	public boolean isFileListener() {
		return false;
	}

	private boolean getVariable(String name) {
		return "true".equals(getInstallData().getVariable(name));
	}

}
