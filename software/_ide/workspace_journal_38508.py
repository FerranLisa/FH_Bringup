# 2026-09-22T20:44:39.568774700
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
domain = platform.add_domain(cpu = "psu_cortexa53_2",os = "standalone",name = "fsbl_ibert_domain",display_name = "fsbl_ibert_domain",support_app = "zynqmp_fsbl",generate_dtb = False,hw_boot_bin = "")

comp = client.create_app_component(name="FH_Carrier_IBERT_FSBL",platform = "$COMPONENT_LOCATION/../FH_Carrier_platform/export/FH_Carrier_platform/FH_Carrier_platform.xpfm",domain = "fsbl_ibert_domain",template = "zynqmp_fsbl")

comp = client.get_component(name="FH_Carrier_IBERT_FSBL")
comp.build()

status = platform.build()

comp.build()

comp.build()

vitis.dispose()

