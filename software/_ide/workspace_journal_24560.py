# 2026-10-25T10:36:56.166647100
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup_Linux/exports/gmax3412_scheduler/FH_Carrier_Bringup_GMAX3412_Scheduler.xsa")

status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

vitis.dispose()

