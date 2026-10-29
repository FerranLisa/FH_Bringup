# 2026-09-21T14:20:43.518499300
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.create_platform_component(name = "FH_Carrier_platform",hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup/design_1_wrapper.xsa",os = "standalone",cpu = "psu_cortexa53_0",domain_name = "standalone_psu_cortexa53_0",architecture = "64-bit",compiler = "gcc")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.build()

comp = client.get_component(name="FH_Carrier_test")
status = comp.clean()

comp.build()

status = comp.clean()

comp.build()

comp.build()

comp.build()

comp.build()

status = comp.clean()

comp.build()

comp.build()

status = comp.clean()

status = platform.build()

status = comp.clean()

status = comp.clean()

comp.build()

comp.build()

vitis.dispose()

