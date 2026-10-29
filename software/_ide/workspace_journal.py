# 2026-10-29T15:20:26.367396600
import vitis

client = vitis.create_client()
client.set_workspace(path="software")

platform = client.get_component(name="FH_Carrier_platform")
status = platform.build()

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

vitis.dispose()

vitis.dispose()

