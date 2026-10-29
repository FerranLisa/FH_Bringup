# 2026-09-21T15:44:00.876054800
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

status = comp.clean()

comp.build()

comp.build()

platform = client.get_component(name="FH_Carrier_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup/design_1_wrapper.xsa")

status = platform.build()

comp.build()

comp.build()

vitis.dispose()

