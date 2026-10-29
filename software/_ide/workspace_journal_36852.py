# 2026-09-30T22:22:21.969653200
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup_Linux/FH_Carrier_Bringup_top.xsa")

status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
status = comp.clean()

comp.build()

vitis.dispose()

vitis.dispose()

