# 2026-10-24T11:52:32.833265200
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup_Linux/exports/gmax3412_emulator/FH_Carrier_Bringup_GMAX3412_Emulator.xsa")

vitis.dispose()

