# 2026-10-04T11:11:30.997914400
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup_Linux/debug/FH_Carrier_Bringup_RX_ILA.xsa")

status = platform.build()

status = platform.update_hw(hw_design = "R:\RX_ILA\debug\FH_Carrier_Bringup_RX_ILA.xsa")

status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "R:\CLOCK_MONITOR\debug\FH_Carrier_Bringup_CLOCK_MONITOR.xsa")

status = platform.build()

comp.build()

vitis.dispose()

