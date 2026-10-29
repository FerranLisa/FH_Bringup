# 2026-10-25T22:02:06.051108900
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../../VIVADO/FH_Carrier_Bringup_Linux/exports/gmax3412_pl_ddr/FH_Carrier_Bringup_GMAX3412_PL_DDR.xsa")

status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

