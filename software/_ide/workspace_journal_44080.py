# 2026-10-24T17:14:40.996578600
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup_Linux/exports/gmax3412_capture/FH_Carrier_Bringup_GMAX3412_Capture.xsa")

status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

comp.build()

comp.build()

status = platform.build()

comp.build()

comp.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

status = platform.build()

vitis.dispose()

