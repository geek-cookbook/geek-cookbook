# iBeacons with Home assistant

!!! warning
    This is not a complete recipe - it's an optional additional of the [HomeAssistant](/recipes/homeassistant/) "recipe", since it only applies to a subset of users

One of the most useful features of Home Assistant is location awareness. I don't care if someone opens my office door when I'm home, but you bet I care about (_and want to be notified_) it if I'm away!

## Ingredients

1. [HomeAssistant](/recipes/home-assistant/) per recipe
2. iBeacon(s) - This recipe is for https://s.click.aliexpress.com/e/bzyLCnAp
4. [LightBlue Explorer](https://itunes.apple.com/nz/app/lightblue-explorer/id557428110?mt=8)

## Preparation

### Write UUID to iBeacon

The iBeacons come with no UUID. We use the LightBlue Explorer app to pair with them (_code is "123456"_), and assign own own UUID.

Generate your own UUID, or get a random one at https://www.uuidgenerator.net/

Plug in your iBeacon, launch LightBlue Explorer, and find your iBeacon. The first time you attempt to interrogate it, you'll be prompted to pair. Although it's not recorded anywhere in the documentation (_grr!_), the pairing code is **123456**

Having paired, you'll be able to see the vital statistics of your iBeacon.
