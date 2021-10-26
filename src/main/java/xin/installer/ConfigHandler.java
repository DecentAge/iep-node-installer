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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.logging.Logger;

final class ConfigHandler {
	private static final Logger logger = Logger.getLogger(ConfigHandler.class.getName());

	private static final String JAR = "xin.jar";
	private static final String SERVER = "http://localhost";
	private static final int[] PORTS = { 23457, 9876 };
	private static final String VAR_PREFIX = "xin.installer.";

	public static final String FILE_PATH = "conf/installer.properties";
	public static final String VAR_CLEAN_INSTALL_DIR = VAR_PREFIX + "cleanInstallDir";
	public static final String VAR_SHUTDOWN_SERVER = VAR_PREFIX + "shutdownServer";
	public static final String VAR_FILE_CONTENTS = "settings";

	public boolean isServerRunningByAPI() {
		for (int port : PORTS) {
			try {
				URL url = new URL(SERVER + ':' + port + "/api?requestType=getState");
				HttpURLConnection conn = (HttpURLConnection) url.openConnection();
				conn.setRequestMethod("GET");
				return handleAPIResponse(conn);
			} catch (IOException e) {
				logger.severe("isServerRunning on port: " + port + " " + e.getMessage());
			}
		}
		return false;
	}

	public boolean shutdownServer() {
		if (!shutdownServerByAPI()) {
			return shutdownServerByCommand();
		}
		return false;
	}

	public boolean shutdownServerByAPI() {
		for (int port : PORTS) {
			try {
				URL url = new URL(SERVER + ':' + port + "/api?requestType=shutdown");
				HttpURLConnection conn = (HttpURLConnection) url.openConnection();
				conn.setRequestMethod("POST");
				return handleAPIResponse(conn);
			} catch (IOException e) {
				logger.severe("shutdownServer on port: " + port + " " + e.getMessage());
			}
		}
		return false;
	}

	public boolean shutdownServerByCommand() {
		String command = "bin/stop.sh";
		String[] cmd = { "sh", command };

		try {
			logger.info("Trying to shutdown server using shell");
			Process process = Runtime.getRuntime().exec(cmd);
			process.waitFor();
			handleShellResponse(process);

		} catch (IOException | InterruptedException e) {
			logger.info("Could not shutdown server by calling " + command);
		}
		return true;
	}

	private boolean handleAPIResponse(HttpURLConnection conn) throws IOException {
		Boolean responseSuccess = null;
		int responseCode = conn.getResponseCode();
		InputStream inputStream;
		if (200 <= responseCode && responseCode <= 299) {
			responseSuccess = true;
			inputStream = conn.getInputStream();
		} else {
			inputStream = conn.getErrorStream();
			responseSuccess = false;
		}

		BufferedReader in = new BufferedReader(new InputStreamReader(inputStream));

		StringBuilder response = new StringBuilder();
		String currentLine;
		while ((currentLine = in.readLine()) != null)
			response.append(currentLine);

		in.close();
		String responseString = response.toString();

		logger.info("Server response with status " + responseSuccess + " was: " + responseString);

		if (!responseSuccess || responseString.contains("errorCode")) {
			return false;
		}
		return responseSuccess;
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

	public boolean isXinInstallDir(String path) {
		return path != null && Files.exists(Paths.get(path, JAR));
	}

	public boolean cleanXinInstallDir(String installPath, boolean retry) {
		if (isXinInstallDir(installPath)) {
			if (rmdir(installPath)) {
				return true;
			}
			if (retry) {
				for (int tries = 3; tries > 0; tries--) {
					try {
						Thread.sleep(5000);
					} catch (InterruptedException e) {
						break;
					}
					if (rmdir(installPath)) {
						return true;
					}
				}
			}
		}
		return false;
	}

	private boolean rmdir(String path) {
		try {
			for (Path p : Files.walk(Paths.get(path)).sorted(Comparator.reverseOrder()).toArray(Path[]::new)) {
				Files.delete(p);
			}
		} catch (IOException e) {
			return false;
		}
		return true;
	}

}
