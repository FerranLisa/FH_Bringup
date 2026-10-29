# 2026-09-21T14:33:47.511641400
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

client.delete_component(name="FH_Carrier_test")

client.delete_component(name="FH_Carrier_test")

comp = client.create_app_component(name="FH_Carrier_Test",platform = "$COMPONENT_LOCATION/../FH_Carrier_platform/export/FH_Carrier_platform/FH_Carrier_platform.xpfm",domain = "standalone_psu_cortexa53_0")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
status = comp.clean()

comp.build()

component = client.get_component(name="FH_Carrier_Test")

lscript = component.get_ld_script(path="C:\Projects\FH_Bringup\software\FH_Carrier_Test\src\lscript.ld")

lscript.regenerate()

vitis.dispose()

