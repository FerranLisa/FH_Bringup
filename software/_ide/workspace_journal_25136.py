# 2026-10-24T19:06:32.823151400
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

vitis.dispose()

