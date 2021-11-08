package xin.installer;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import com.izforge.izpack.api.adaptator.IXMLElement;
import com.izforge.izpack.api.data.binding.OsModel;
import com.izforge.izpack.api.exception.CompilerException;
import com.izforge.izpack.compiler.listener.SimpleCompilerListener;
import com.izforge.izpack.compiler.packager.IPackager;
import com.izforge.izpack.util.OsConstraintHelper;

public class PackFilterCompilerListener extends SimpleCompilerListener {
	private static final Logger logger = Logger.getLogger(PackFilterCompilerListener.class.getName());

	public PackFilterCompilerListener() {
		super();
	}

	@Override
	public Map<String, ?> reviseAdditionalDataMap(Map<String, ?> existentDataMap, IXMLElement element)
			throws CompilerException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void notify(String position, int state, IXMLElement data, IPackager packager) {

		if (!"addPacksSingle".equals(position))
			return;

		IXMLElement packsRoot = data.getFirstChildNamed("packs");

		if (packsRoot != null) {
			List<IXMLElement> packsRootList = packsRoot.getChildrenNamed("pack");

			List<IXMLElement> packsRemoveList = new ArrayList<IXMLElement>();
			for (IXMLElement packElement : packsRootList) {

				List<OsModel> osConstraintList = OsConstraintHelper.getOsList(packElement);

				if (!isOsConstraintFullfiled("unix", osConstraintList)) {
					logger.info("Excluding pack " + packElement.getAttribute("name"));
					packsRemoveList.add(packElement);
				}
			}
			packsRootList.removeAll(packsRemoveList);
		}
	}

	private boolean isOsConstraintFullfiled(String osFamily, List<OsModel> osConstraintList) {

		if (osConstraintList.isEmpty())
			return true;

		for (OsModel osModel : osConstraintList) {

			if (osFamily.equals(osModel.getFamily())) {
				return true;
			}
		}
		return false;
	}

}
