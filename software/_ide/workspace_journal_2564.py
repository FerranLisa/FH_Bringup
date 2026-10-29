# 2026-10-25T10:43:54.312636700
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

vitis.dispose()

vitis.dispose()

