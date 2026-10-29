# 2026-10-24T12:06:29.486706900
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

vitis.dispose()

